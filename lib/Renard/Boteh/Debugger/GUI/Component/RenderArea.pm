use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI::Component::RenderArea;
# ABSTRACT: A render area

use Moo;
use Glib::Object::Subclass
	'Gtk3::Bin';

use Cairo;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Glib qw(TRUE FALSE);

=attr drawing_area

A L<Gtk3::DrawingArea>.

=cut
has drawing_area => (
	is => 'rw',
	isa => InstanceOf['Gtk3::DrawingArea'],
);

=attr scrolled_window

A L<Gtk3::ScrolledWindow>.

=cut
has scrolled_window => (
	is => 'rw',
	isa => InstanceOf['Gtk3::ScrolledWindow'],
);

=attr cairo_surface

A L<Cairo::Surface> that the rendering is drawn on to.

=cut
has cairo_surface => (
	is => 'rw',
	isa => InstanceOf['Cairo::Surface'],
);

=method BUILD

Sets up the render area component.

=cut
method BUILD(@) {
	my $drawing_area = Gtk3::DrawingArea->new();
	$self->drawing_area( $drawing_area );
	$drawing_area->signal_connect( draw => callback(
			(InstanceOf['Gtk3::DrawingArea']) $widget,
			(InstanceOf['Cairo::Context']) $cr) {
		$self->on_draw_page_cb( $cr );

		return TRUE;
	}, $self);

	$drawing_area->add_events([ qw/button-press-mask pointer-motion-mask/ ]);
	$drawing_area->signal_connect( 'motion-notify-event' =>
		\&on_motion_notify_event_cb, $self );
	$drawing_area->add_events('scroll-mask');

	my $scrolled_window = Gtk3::ScrolledWindow->new();
	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_vexpand(TRUE);

	$scrolled_window->add($drawing_area);
	$scrolled_window->set_policy( 'automatic', 'automatic');
	$self->scrolled_window($scrolled_window);

	my @adjustments = (
		$self->scrolled_window->get_hadjustment,
		$self->scrolled_window->get_vadjustment,
	);
	#my $callback = fun($adjustment) {
		#$self->signal_emit('update-scroll-adjustment');
	#};
	#for my $adjustment (@adjustments) {
		#$adjustment->signal_connect( 'value-changed' => $callback );
		#$adjustment->signal_connect( 'changed' => $callback );
	#}

	$self->add( $scrolled_window );
}

method _trigger_rendering() {
	my $render_tree = $self->rendering->render_tree;

	my $sz = $render_tree->attributes->{bounds}->size;
	my $surface = Cairo::ImageSurface->create('argb32', $sz->width, $sz->height);
	$self->cairo_surface( $surface );

	my $cr = Cairo::Context->create( $surface );

	method _walk_cairo_render( $node, $cr ) {
		my @daughters = $node->daughters;
		if( exists $node->attributes->{render} ) {
			my $el = $node->attributes->{render}->render_cairo( $cr );
		}
		for my $daughter (@daughters) {
			$self->_walk_cairo_render( $daughter, $cr );
		}
	};

	$self->_walk_cairo_render( $render_tree, $cr );

	$self->drawing_area->set_size_request( $sz->width, $sz->height );
}

=callback on_draw_page_cb

Callback for the C<draw> signal on the drawing area.

=cut
method on_draw_page_cb($cr) {
	return unless $self->cairo_surface;

	$cr->set_source_surface($self->cairo_surface,
		0,
		0);

	$cr->paint;
}

=callback on_motion_notify_event_cb

Call back for the C<motion-notify-event> signal for the drawing area.

=cut
callback on_motion_notify_event_cb($widget, $event, $self) {
	my $render_tree = $self->rendering->render_tree;

	method _walk_motion_notify_event( $node, $event ) {
		my @nodes = ();
		my @daughters = $node->daughters;
		my $contains = $node->attributes->{bounds}->contains_point(
			Renard::Yarn::Graphene::Point->new(
				x => $event->x,
				y => $event->y )
		);
		if( $contains ) {
			push @nodes, $node;
			for my $daughter (@daughters) {
				push @nodes, $self->_walk_motion_notify_event( $daughter, $event );
			}
		}

		return @nodes;
	};

	my @nodes = $self->_walk_motion_notify_event( $render_tree, $event );
	$self->rendering->selection( \@nodes );

	return TRUE;
}

with qw(
	Renard::Boteh::Debugger::GUI::Component::Role::HasTree
);


1;

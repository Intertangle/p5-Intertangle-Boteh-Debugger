use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI::Component::RenderArea;
# ABSTRACT: A render area

use Mu;
use Glib::Object::Subclass
	'Gtk3::Bin';

use Object::Util;
use Cairo;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Glib qw(TRUE FALSE);

=attr canvas

A L<Gtk3::Layout>.

=cut
lazy canvas => method() {
	my $canvas = Gtk3::Layout->new();

	$canvas->signal_connect( draw => callback(
			(InstanceOf['Gtk3::Layout']) $widget,
			(InstanceOf['Cairo::Context']) $cr) {
		$self->on_draw_page_cb( $cr );

		return TRUE;
	}, $self);

	$canvas->add_events([ qw/button-press-mask pointer-motion-mask/ ]);
	$canvas->signal_connect( 'motion-notify-event' =>
		\&on_motion_notify_event_cb, $self );

	$canvas;
}, isa => InstanceOf['Gtk3::Layout'];

=attr scrolled_window

A L<Gtk3::ScrolledWindow>.

=cut
lazy scrolled_window => method() {
	my $scrolled_window = Gtk3::ScrolledWindow->new();

	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_vexpand(TRUE);
	$scrolled_window->set_policy( 'automatic', 'automatic');

	$scrolled_window;
}, isa => InstanceOf['Gtk3::ScrolledWindow'];

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
	$self->add(
		$self->scrolled_window->$_tap(
			add => $self->canvas
		)
	);

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
}

method _trigger_rendering() {
	my $render_graph = $self->rendering->render_graph;

	my $sz = $render_graph->graph->attributes->{bounds}->size;

	$self->canvas->set_size( $sz->width, $sz->height );

	$self->canvas->queue_draw;

	#exit;
}

method render_cairo() {
	my $render_graph = $self->rendering->render_graph;
	my $sz = $render_graph->graph->attributes->{bounds}->size;

	my $h = $self->scrolled_window->get_hadjustment;
	my $v = $self->scrolled_window->get_vadjustment;

	my $bounds = Renard::Yarn::Graphene::Rect->new(
		origin => Renard::Yarn::Graphene::Point->new(
			x => $h->get_value,
			y => $v->get_value,
		),
		size => Renard::Yarn::Graphene::Size->new(
			width => $h->get_page_size,
			height => $v->get_page_size,
		),
	);

	my $surface = Cairo::ImageSurface->create(
		'argb32',
		$bounds->size->width, $bounds->size->height,
		#$sz->width, $sz->height,
	);

	$self->cairo_surface( $surface );

	use DDP; p $bounds;#DEBUG

	my $cr = Cairo::Context->create( $self->cairo_surface );

	use Renard::Taffeta::Transform::Affine2D::Translation;

	my $render_state =
		Renard::Jacquard::Render::State->new(
			coordinate_system_transform =>
				Renard::Taffeta::Transform::Affine2D::Translation->new(
					translate => [ - $bounds->origin->x, - $bounds->origin->y ],
				)
		);

	$cr->save;

	method _walk_cairo_render( $node, $cr, $bounds, $render_state ) {
		my @daughters = $node->daughters;

		my $renderable = exists $node->attributes->{renderable};
		my ($in_bounds, $res) = $bounds->intersection($node->attributes->{bounds});
		if( $renderable && $in_bounds ) {
			#use DDP; p $node->attributes->{scene_graph}->content->page_number;

			my $state = $node->attributes->{state}->compose( $render_state );
			#my $state = $node->attributes->{state};

			my $el = $node->attributes->{scene_graph}->content->as_taffeta(
				state => $state,
			)->render_cairo( $cr );
			#my $el = $node->attributes->{render}->render_cairo( $cr );
		}
		for my $daughter (@daughters) {
			$self->_walk_cairo_render(
				$daughter,
				$cr,
				$bounds,
				$render_state,
			);
		}
	};

	$self->_walk_cairo_render(
		$render_graph->graph,
		$cr,
		$bounds,
		$render_state,
	);

	$cr->restore;
}

=callback on_draw_page_cb

Callback for the C<draw> signal on the drawing area.

=cut
method on_draw_page_cb($cr) {
	#return unless $self->cairo_surface;

	$self->render_cairo;
	$cr->set_source_surface($self->cairo_surface,
		0, 0,
		#$self->scrolled_window->get_hadjustment->get_value, $self->scrolled_window->get_vadjustment->get_value,
	);

	$cr->paint;
}

=callback on_motion_notify_event_cb

Call back for the C<motion-notify-event> signal for the drawing area.

=cut
callback on_motion_notify_event_cb($widget, $event, $self) {
	my $render_graph = $self->rendering->render_graph;
	my @nodes = $render_graph->hit_test_nodes( [ 0 + $event->x, 0 + $event->y ] );
	$self->rendering->selection( \@nodes );

	return TRUE;
}

with qw(
	Renard::Boteh::Debugger::GUI::Component::Role::HasTree
);


1;

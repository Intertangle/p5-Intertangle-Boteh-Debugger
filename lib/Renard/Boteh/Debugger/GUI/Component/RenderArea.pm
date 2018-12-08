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

	my $sz = $render_graph->size;

	$self->canvas->set_size( $sz->width, $sz->height );

	$self->canvas->queue_draw;

	if( $ENV{RENARD_BOTEH_DEBUGGER_EXIT} ) {
		Glib::Timeout->add(2000, sub { exit; });
	}
}

method render_cairo() {
	use Renard::Jacquard::View::Taffeta;
	use Renard::Taffeta::Graphics::Rectangle;

	my $render_graph = $self->rendering->render_graph;
	my $sz = $render_graph->size;

	my $h = $self->scrolled_window->get_hadjustment;
	my $v = $self->scrolled_window->get_vadjustment;

	my $view = Renard::Jacquard::View::Taffeta->new(
		viewport => Renard::Taffeta::Graphics::Rectangle->new(
			origin => [ $h->get_value, $v->get_value ],
			width => $h->get_page_size,
			height => $v->get_page_size,
		)
	);
	my $bounds = $view->viewport->identity_bounds;
	use Module::Load; load 'DDP'; p $bounds;#DEBUG

	my $surface = Cairo::ImageSurface->create(
		'argb32',
		$bounds->size->width, $bounds->size->height,
		#$sz->width, $sz->height,
	);

	$self->cairo_surface( $surface );

	my $cr = Cairo::Context->create( $self->cairo_surface );

	$render_graph->render_to_cairo( $cr, $view );

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

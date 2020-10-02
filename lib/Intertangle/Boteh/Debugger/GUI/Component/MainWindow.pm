use Renard::Incunabula::Common::Setup;
package Intertangle::Boteh::Debugger::GUI::Component::MainWindow;
# ABSTRACT: A window

use Mu;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::API::Gtk3::Helper;

use Intertangle::Boteh::Debugger::GUI::Component::Outline;
use Intertangle::Boteh::Debugger::GUI::Component::RenderArea;
use Intertangle::Boteh::Debugger::GUI::Component::ListArea;

use Intertangle::Boteh::Debugger::GUI::Rendering;

use Glib 'TRUE', 'FALSE';

lazy _window => method() { # :ReturnType(InstanceOf['Gtk3::Window'])
	$self->builder->get_object('main-window')
}, isa => InstanceOf['Gtk3::Window'];

=attr outline

A L<Intertangle::Boteh::Debugger::GUI::Component::Outline>.

=cut
lazy outline => method() {
	Intertangle::Boteh::Debugger::GUI::Component::Outline->new;
};

=attr render_area

A L<Intertangle::Boteh::Debugger::GUI::Component::RenderArea>.

=cut
lazy render_area => method() {
	Intertangle::Boteh::Debugger::GUI::Component::RenderArea->new;
};

=attr list_area

A L<Intertangle::Boteh::Debugger::GUI::Component::ListArea>.

=cut
lazy list_area => method() {
	Intertangle::Boteh::Debugger::GUI::Component::ListArea->new;
};

=method BUILD

Sets up the main window component.

=cut
method BUILD() {
	$self->builder->get_object('top-hbox')
		->add1( $self->outline );
	$self->builder->get_object('application-box')
		->add2( $self->render_area );
	$self->builder->get_object('top-hbox')
		->add2( $self->list_area );

	$self->_window->signal_connect(
		destroy => \&on_application_quit_cb, $self );
	$self->_window->set_default_size( 800, 600 );
}

=callback on_application_quit_cb

  callback on_application_quit_cb( $event, $self )

Callback that stops the L<Gtk3> main loop.

=cut
callback on_application_quit_cb( $event, $self ) {
	Gtk3::main_quit;
}

=method show_all

Show the main window component.

=cut
method show_all() {
	$self->_window->show_all;
}

=method load_graph

Load a scene graph to render.

=cut
method load_graph( $graph ) {
	my $rendering = Intertangle::Boteh::Debugger::GUI::Rendering->new(
		graph => $graph
	);
	$self->outline->rendering( $rendering );
	$self->render_area->rendering( $rendering );
	$self->list_area->rendering( $rendering );
}

with qw(
	Intertangle::API::Gtk3::Component::Role::FromBuilder
	Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName
);

1;

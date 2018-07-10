use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI;
# ABSTRACT: A graphical debugger for a Jacquard scene graph

use Mu;

use Renard::Boteh::Debugger::GUI::Component::MainWindow;

=attr main_window

The main window L<Renard::Boteh::Debugger::GUI::Component::MainWindow> for the debugger.

=cut
lazy main_window => method() {
	Renard::Boteh::Debugger::GUI::Component::MainWindow->new;
};

=method process_arguments

Process arguments for debugger.

=cut
method process_arguments() {
}

=method main

Entry point for the debugger.

=cut
method main() {
	$self = __PACKAGE__->new unless ref $self;
	$self->process_arguments;
	$self->run;
}

=method run

Starts the debugger main loop.

=cut
method run() {
	$self->main_window->show_all;
	Gtk3::main;
}

1;

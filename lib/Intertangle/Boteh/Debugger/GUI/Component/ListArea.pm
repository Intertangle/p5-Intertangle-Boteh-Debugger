use Renard::Incunabula::Common::Setup;
package Intertangle::Boteh::Debugger::GUI::Component::ListArea;
# ABSTRACT: A list area

use Mu;
use Object::Util;
use Glib::Object::Subclass
	'Gtk3::Bin';
use Glib qw(TRUE FALSE);
use Module::Load;

=attr list_box

A L<Gtk3::ListBox>.

=cut
lazy list_box => method() {
	Gtk3::ListBox->new;
};

=method BUILD

Sets up the list area component.

=cut
method BUILD(@) {
	my $frame = Gtk3::Frame->new('Selection data');
	my $scrolled_window = Gtk3::ScrolledWindow->new;
	$scrolled_window->set_vexpand(TRUE);
	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_policy( 'automatic', 'automatic');

	$self->add( $frame->$_tap(
			add => $scrolled_window->$_tap(
				add => $self->list_box )
		)
	);
}

method _trigger_rendering() {
	$self->rendering->signal_connect(
		'updated-selection' => \&on_updated_selection_cb, $self );
}

=callback on_updated_selection_cb

Call back for the C<updated-selection> signal.

=cut
callback on_updated_selection_cb($rendering, $self) {
	$self->list_box->remove($_) for $self->list_box->get_children;

	for my $node ( reverse @{ $self->rendering->selection } ) {
		my $row = Gtk3::ListBoxRow->new;
		my $box = Gtk3::Box->new( 'horizontal', 0 );

		load 'DDP';
		my $str = Data::Printer::np($node->attributes, colored => 0, class => { internals  => 0, }, );
		$box->add( Gtk3::Label->new( $node->address . $str ) );

		$row->add($box);

		$self->list_box->add( $row );
	}
	$self->list_box->show_all;
}

with qw(
	Intertangle::Boteh::Debugger::GUI::Component::Role::HasTree
);

1;

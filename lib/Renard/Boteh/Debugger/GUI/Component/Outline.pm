use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI::Component::Outline;
# ABSTRACT: An outline

use Mu;
use Glib::Object::Subclass
	'Gtk3::Bin';

use Glib 'TRUE', 'FALSE';
use List::UtilsBy qw(nsort_by);

use constant COLUMNS => {
	ADDRESS           => { index => 0, type => 'Glib::String' },
	NAME              => { index => 1, type => 'Glib::String' },
	BACKGROUND_COLOR  => { index => 2, type => 'Glib::String' },
};

=attr tree_view

A C<Gtk3::TreeView> for the outline.

=cut
lazy tree_view => method() {
	Gtk3::TreeView->new;
};

=attr tree_store

A L<Gtk3::TreeStore> for the outline.

=cut
has tree_store => (
	is => 'rw',
	default => method() {
		Gtk3::TreeStore->new(
			map { $_->{type} }
			nsort_by { $_->{index} }
			values %{ COLUMNS() }
		);
	},
);

method _trigger_rendering() {
	my $data = $self->tree_store;

	$data->clear;

	my $tree = $self->rendering->render_tree;
	my $iter = undef;
	my @stack = ($iter);

	$tree->walk_down({ callback => fun($node, $options) {
		$options->{_depth} //= 0;
		pop @{ $options->{stack} } while 1 + $options->{_depth} < scalar @{ $options->{stack} };
		my $parent_iter = $options->{stack}[-1];

		my $iter = $data->append( $parent_iter );
		push @{ $options->{stack} }, $iter;

		$data->set( $iter,
			COLUMNS->{'ADDRESS'}{'index'} =>
				$node->address,
			COLUMNS->{'NAME'}{'index'} =>
				exists $node->attributes->{render} ? ref $node->attributes->{render} : '' );

		1;
	}, stack => \@stack });

	$self->rendering->signal_connect(
		'updated-selection' => \&on_updated_selection_cb, $self );
}

=callback on_updated_selection_cb

Call back for the C<updated-selection> signal.

=cut
callback on_updated_selection_cb($rendering, $self) {
	$self->tree_view->collapse_all;
	my %sel_addr = map {
		( $_->address => 1 )
	} @{ $self->rendering->selection };
	$self->tree_store->foreach(
		fun($model, $path, $iter) {
			my $node_addr = $model->get_value( $iter, COLUMNS->{'ADDRESS'}{'index'});
			$model->set(
				$iter,
				COLUMNS->{'BACKGROUND_COLOR'}{'index'},
				exists $sel_addr{$node_addr} ? 'red' : 'white'
			);
			$self->tree_view->expand_to_path($path) if exists $sel_addr{$node_addr};

			return FALSE;
		}
	);
}

=method BUILD

Sets up the outline component.

=cut
method BUILD(@) {
	my $frame = Gtk3::Frame->new('Outline');
	my $scrolled_window = Gtk3::ScrolledWindow->new;
	$scrolled_window->set_vexpand(TRUE);
	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_policy( 'automatic', 'automatic');

	$self->tree_view->insert_column(
		Gtk3::TreeViewColumn->new_with_attributes(
			'Address',
			Gtk3::CellRendererText->new,
			text => COLUMNS->{'ADDRESS'}{'index'},
			'cell-background' => COLUMNS->{'BACKGROUND_COLOR'}{'index'},
		),
	0);
	$self->tree_view->insert_column(
		Gtk3::TreeViewColumn->new_with_attributes(
			'Name',
			Gtk3::CellRendererText->new,
			text => COLUMNS->{'NAME'}{'index'},
			'cell-background' => COLUMNS->{'BACKGROUND_COLOR'}{'index'},
		),
	1);

	$self->tree_view->set( 'headers-visible', FALSE );

	$self->tree_view->set_model( $self->tree_store );

	$scrolled_window->add( $self->tree_view );
	$frame->add( $scrolled_window );
	$self->add( $frame );
}

with qw(
	Renard::Boteh::Debugger::GUI::Component::Role::HasTree
);

1;

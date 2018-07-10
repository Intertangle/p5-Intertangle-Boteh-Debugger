use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI::Rendering;

use Mu;
use Renard::Jacquard::Render::GenerateTree;
use Renard::Incunabula::Common::Types qw(InstanceOf ArrayRef);
use Renard::Jacquard::Types qw(Actor);
use Glib::Object::Subclass
	'Glib::Object',
	signals => {
		'updated-selection' => { },
	},
	;

=classmethod FOREIGNBUILDARGS

Initialises the L<Glib::Object> superclass.

=cut
classmethod FOREIGNBUILDARGS(@) { () }

=attr tree

The scene graph.

=cut
has tree => (
	is => 'ro',
	isa => Actor,
	required => 1,
);

=attr render_tree

The render tree

=cut
lazy render_tree => method() {
	my $tree = Renard::Jacquard::Render::GenerateTree->get_render_tree(
				root => $self->tree );
}, isa => InstanceOf['Tree::DAG_Node'];

=attr selection

An C<ArrayRef> of render nodes that are in the current selection.

When set, this object emits an C<updated-selection> signal.

=cut
has selection => (
	is => 'rw',
	isa => ArrayRef[InstanceOf['Tree::DAG_Node']],
	default => sub { [] },
	trigger => 1,
);

method _trigger_selection() {
	$self->signal_emit( 'updated-selection' );
}

1;

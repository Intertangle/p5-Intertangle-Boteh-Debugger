use Renard::Incunabula::Common::Setup;
package Intertangle::Boteh::Debugger::GUI::Rendering;

use Mu;
use Renard::Incunabula::Common::Types qw(InstanceOf ArrayRef);
use Intertangle::Jacquard::Types qw(Actor);
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

=attr graph

The scene graph.

=cut
has graph => (
	is => 'ro',
	isa => InstanceOf['Intertangle::Jacquard::Graph::Taffeta'],
	required => 1,
);

=attr render_graph

The render graph.

=cut
lazy render_graph => method() {
	my $tree = $self->graph->to_render_graph;
}, isa => InstanceOf['Intertangle::Jacquard::Graph::Render'];

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

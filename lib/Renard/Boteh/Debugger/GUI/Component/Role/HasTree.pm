use Renard::Incunabula::Common::Setup;
package Renard::Boteh::Debugger::GUI::Component::Role::HasTree;
# ABSTRACT: A role for tree

use Moo::Role;

has rendering => (
	is => 'rw',
	trigger => 1,
);

1;

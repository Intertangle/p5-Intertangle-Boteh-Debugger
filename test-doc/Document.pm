use Renard::Incunabula::Common::Setup;
package Document;
# ABSTRACT: A test for Renard-Boteh

use Mu;
use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Format::PDF::Devel::TestHelper;
use POSIX qw(ceil);

use aliased 'Renard::Jacquard::Actor';
use aliased 'Renard::Jacquard::Actor::Taffeta::Group';
use aliased 'Renard::Jacquard::Actor::Taffeta::Graphics';
use aliased 'Renard::Jacquard::Layout::Fixed';
use aliased 'Renard::Jacquard::Layout::All';
use aliased 'Renard::Jacquard::Layout::Affine2D';
use aliased 'Renard::Jacquard::Layout::AutofillGrid';
use aliased 'Renard::Jacquard::Layout::Composed';
use Renard::Jacquard::Graph::Taffeta;

package Jacquard::Content::PDFPage {
	use Renard::Incunabula::Common::Setup;
	use Renard::Yarn::Types qw(Rect);
	use Renard::Jacquard::Types qw(State);
	use Renard::Jacquard::Render::State;
	use aliased 'Renard::Taffeta::Graphics::Image::PNG';

	use Mu;

	has [ qw(document page_number) ] => ( is => 'ro', required => 1 );

	lazy rendered_page => method() {
		$self->document->get_rendered_page(
			page_number => $self->page_number,
		);
	};

	lazy data => method() {
		say "Getting data for @{[ $self->page_number ]}";
		$self->rendered_page->png_data,
	};

	method bounds( $state = Renard::Jacquard::Render::State->new ) :ReturnType(Rect) {
		#require Carp::REPL; Carp::REPL->import('repl'); repl();#DEBUG
		my $identity_bounds = Renard::Yarn::Graphene::Rect->new(
			origin => Renard::Yarn::Graphene::Point->new(0, 0),
			size   => Renard::Yarn::Graphene::Size->new(
				width => $self->rendered_page->width,
				height => $self->rendered_page->height,
			),
		);

		return $identity_bounds if $state->transform->is_identity;

		my $transformed_rect = $state->transform->apply_to_bounds( $identity_bounds );
	}

	method as_taffeta(
		(State) :$state = Renard::Jacquard::Render::State->new,
		:$taffeta_args = {} ) {
		PNG->new(
			data => $self->data,
			transform => $state->transform,
			%$taffeta_args,
		);
	}
};

use Renard::Taffeta::Transform::Affine2D::Scaling;

lazy filename => method() {
	Renard::Incunabula::Format::PDF::Devel::TestHelper
		->pdf_reference_document_path;
};

lazy document => method() {
	Renard::Incunabula::Format::PDF::Document->new(
		filename => $self->filename,
	);
};

lazy graph => method() {
	my $top = Group->new(
		layout => Affine2D->new( transform =>
			Renard::Taffeta::Transform::Affine2D::Scaling
				->new(
					scale => [0.2, 0.2],
				)
		),
	);


	my $last_page;
	$last_page = $self->document->last_page_number;
	#$last_page = 2;
	#$last_page = 10;
	my $number_of_columns = 2;

	my $root =  Group->new(
		layout => AutofillGrid->new(
			rows => ceil($last_page/$number_of_columns),
			intergrid_space => 10,
			columns => $number_of_columns,
		),
	);
	$top->add_child($root);

	$root->add_child( $self->create_page_node($_) ) for 1..$last_page;

	return Renard::Jacquard::Graph::Taffeta->new(
		graph => $root,
	)
	#return $top;
};

method create_page_node( $page_number ) {
	my $page_group = Group->new(
		layout => Fixed->new
	);

	my $pdf_page = Jacquard::Content::PDFPage->new(
		document => $self->document,
		page_number => $page_number
	);

	$page_group->add_child(
		Graphics->new(
			content => $pdf_page,
		),
		layout => {
			x => 0,
			y => 0,
		},
	);

	$page_group;

}

with qw(Renard::Boteh::Role::Sceneable);

1;

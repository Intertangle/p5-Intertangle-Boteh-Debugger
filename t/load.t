#!/usr/bin/env perl

use Renard::Incunabula::Common::Setup;
use Test::Most tests => 1;

subtest "Load module" => sub {
	use_ok 'Renard::Boteh::Debugger::GUI';
};

done_testing;

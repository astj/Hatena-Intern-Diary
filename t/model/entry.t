package t::Intern::Diary::Model::Entry;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent qw(Test::Class);

use Test::Intern::Diary;

use Test::More;

sub _require : Test(startup => 1) {
    my ($self) = @_;
    require_ok 'Intern::Diary::Model::Entry';
}

__PACKAGE__->runtests;

1;
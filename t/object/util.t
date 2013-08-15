package t::Intern::Diary::Util;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent 'Test::Class';

use Test::More;
use DateTime;

use Test::Intern::Diary;

sub _require : Test(startup => 1) {
    my ($self) = @_;
    require_ok 'Intern::Diary::Util';
}

sub require_argument : Test(1) {
    my $self = shift;
    my $now = DateTime->now();

    my $args = {hoge => $now};
    my $returned_obj = Intern::Diary::Util->require_argument($args, 'hoge', 'DateTime');

    is $returned_obj->epoch, $now->epoch;
}

__PACKAGE__->runtests;

1;

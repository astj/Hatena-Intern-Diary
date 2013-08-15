package t::Intern::Diary::Model::User;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::Intern::Diary;

use Test::More;

use DateTime;
use DateTime::Format::MySQL;

use parent 'Test::Class';

sub _use : Test(startup => 1) {
    my ($self) = @_;
    use_ok 'Intern::Diary::Model::User';
}

sub _accessor : Test(2) {
    my $diary = Intern::Diary::Model::User->new(
        user_id => 2 ,
	name => 'astj',
    );

    is $diary->user_id, 2;
    is $diary->name, 'astj';
}

__PACKAGE__->runtests;

1;

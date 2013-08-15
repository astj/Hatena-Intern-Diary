package t::Intern::Diary::Model::Diary;

use strict;
use warnings;
use utf8;
use lib 't/lib';
use Encode;

use Test::Intern::Diary;

use Test::More;

use DateTime;
use DateTime::Format::MySQL;

use parent 'Test::Class';

sub _use : Test(startup => 1) {
    my ($self) = @_;
    use_ok 'Intern::Diary::Model::Diary';
}

sub _accessor : Test(5) {
    my $now = DateTime->now;
    my $diary = Intern::Diary::Model::Diary->new(
        diary_id => 1,
        user_id => 2,
        title => encode('utf8', 'たいとる'),
        content => encode('utf8', '日記を書きました。'),
        date => DateTime::Format::MySQL->format_date($now),
    );
    is $diary->diary_id, 1;
    is $diary->user_id, 2;
    is $diary->title, 'たいとる';
    is $diary->content, '日記を書きました。';
    is $diary->date->ymd, $now->ymd;
}

__PACKAGE__->runtests;

1;

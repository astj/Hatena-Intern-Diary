package t::Intern::Diary::Service::User;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent 'Test::Class';

use Test::Intern::Diary;
use Test::Intern::Diary::Factory;

use Test::More;

use Intern::Diary::DBI::Factory;

use DateTime;
use DateTime::Format::MySQL;

sub _require : Test(startup => 1) {
    my ($self) = @_;
    require_ok 'Intern::Diary::Service::User';
}

sub add_user : Test(2) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    use String::Random qw(random_regex);
    my $name = random_regex('test_user_\w{15}');

    my $user = Intern::Diary::Service::User->add_user( $db, +{ name => $name } );

    ok $user, 'add_user succes';
    is $user->name, $name, 'User name matches';

}

sub find_user_by_name : Test(2) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    use String::Random qw(random_regex);
    my $name = random_regex('test_user_\w{15}');

    # create_userは中でfind_user_by_nameを使ってるから返り値を使っちゃいけない気がする
    create_user( name => $name );

    my $user_finded = Intern::Diary::Service::User->find_user_by_name($db, {name=>$name});

    ok $user_finded, 'find_user_by_name success';
    is $user_finded->name, $name, 'User name matches';
}

# insertとdelete_by_idのテスト書けてない

__PACKAGE__->runtests;

1;

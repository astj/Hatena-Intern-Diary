package t::Intern::Diary::Engine::Index;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent 'Test::Class';

use Test::Intern::Diary;
use Test::Intern::Diary::Factory;
use Test::Intern::Diary::Mechanize;

use Test::More;

sub get_root : Test(2) {
    my $mech;

    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok('/'), 'とりあえず/へのアクセスが通る';
        is $mech->uri->path, '/user/login','未Loginだとログイン画面に飛ぶ';
    };

    subtest 'Loginned Access' => sub {
        my $user = create_user;
        $mech = create_mech( user=>$user);
        $mech->get_ok('/'), 'ログインした後に/へのアクセスが通る';
        is $mech->uri->path, sprintf("/diary/list/%s" ,$user->name ), 'Login済みだと自分のDiary一覧に飛ぶ';
    };

}

__PACKAGE__->runtests;

1;

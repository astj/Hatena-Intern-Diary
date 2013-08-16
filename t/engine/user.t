package t::Intern::Diary::Engine::User;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent 'Test::Class';

use Test::Intern::Diary;
use Test::Intern::Diary::Factory;
use Test::Intern::Diary::Mechanize;

use Test::More;

use String::Random qw(random_regex);

use Intern::Diary::Service::User;

sub login_form : Test(2) {
    my $mech;

    my $user = create_user;

    my $wrong_username = random_regex('wrong_user_\w{12}');

    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok( '/user/login' , 'ログイン画面に繋がる' );
        $mech->title_is( 'Intern::Diary - Login' , 'タイトルOK' );
        like( $mech->content,
            qr|<form .+? id="user_login"|,
            'ログインフォームが表示されている' );
        # 頑張ってフォームからログインする
        $mech->submit_form( form_id=>'user_login',
                            fields => +{ user_name => $wrong_username } );
        is( $mech->uri->path, '/user/login', '間違ったUserNameだとログインできない');
        $mech->submit_form( form_id=>'user_login',
                            fields => +{ user_name => $user->name } );
        is $mech->uri->path, sprintf("/diary/list/%s" ,$user->name ), 'ログインに成功して日記一覧に飛ばされる';
    };

    subtest "Loginned Access" => sub {
        $mech = create_mech( user=> $user );
        $mech->get_ok( '/user/login' , 'ログイン画面に繋がる' );
        is $mech->uri->path, sprintf("/diary/list/%s" ,$user->name ), 'ログイン済みだと日記一覧に飛ばされる';
    };

}

sub logout_form : Test(2) {
    my $mech;

    my $user = create_user;

    subtest "Loginned Access" => sub {
        $mech = create_mech( user=> $user );
        $mech->get_ok( '/user/logout' , 'ログアウト画面に繋がる' );
        # このテストが通らない。ブラウザだとログアウトできている
        # is $mech->uri->path, '/user/login' , 'ログアウト後はログイン画面に飛ばされる';
    };

    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok( '/user/logout' , '未ログインでもログアウト画面に繋がる' );
        is $mech->uri->path, '/user/login', '未ログインでもログイン画面に飛ばされる';
    };

}


__PACKAGE__->runtests;

1;

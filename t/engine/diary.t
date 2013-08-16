package t::Intern::Diary::Engine::Diary;

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

use Intern::Diary::Service::Diary;

sub diary_list : Test(3) {
    my $mech;

    my $now = DateTime->now();
    my $now_str = DateTime::Format::MySQL->format_date($now);

    my $title = random_regex('test_title_\w{18}');
    my $content =  random_regex('test_content_\w{30}');

    my $user_A = create_user;
    my $diary = create_diary( user=>$user_A , date => $now, title => $title, content => $content );

    my $user_B = create_user;

    # 主要な中身はゲストアクセスで確認する
    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok( sprintf ( "/diary/list/%s", $user_A->name ), '未ログインでもDiary一覧が読める' );
        $mech->title_is( sprintf ( "Intern::Diary - %s" , $user_A->name ), 'タイトルOK' );
        like( $mech->content,
            qr/<article id="article_$now_str"/,
            '対応する記事IDがある' );
    };

    subtest "Other User's  Access" => sub {
        $mech = create_mech( user=>$user_B);
        $mech->get_ok( sprintf ( "/diary/list/%s", $user_A->name ), '他人のDiary一覧が読める' );
        unlike( $mech->content,
            qr|<a href="/diary/write/$now_str"|,
            '編集ページへのリンクがない' );
    };

    subtest "My Access" => sub {
        $mech = create_mech( user=>$user_A);
        $mech->get_ok( sprintf ( "/diary/list/%s", $user_A->name ), '自分のDiary一覧が読める' );
        like( $mech->content,
            qr|<a href="/diary/write/$now_str"|,
            '編集ページへのリンクがある' );
    };

}

sub diary_read : Test(3) {
    my $mech;

    my $now = DateTime->now();
    my $now_str = DateTime::Format::MySQL->format_date($now);

    my $title = random_regex('test_title_\w{18}');
    my $content =  random_regex('test_content_\w{30}');

    my $user_A = create_user;
    my $diary = create_diary( user=>$user_A , date => $now, title => $title, content => $content );

    my $user_B = create_user;

    # 主要な中身はゲストアクセスで確認する
    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok( sprintf ( "/diary/read/%s/%s", $user_A->name, $now_str ), '未ログインでも記事が読める' );
        $mech->title_is( sprintf ( "Intern::Diary - %s - %s" , $user_A->name, $now->ymd('/') ), 'タイトルOK' );
        like( $mech->content,
            qr/<article id="article_$now_str"/,
            '対応する記事IDがある' );
    };

    subtest "Other User's  Access" => sub {
        $mech = create_mech( user=>$user_B);
        $mech->get_ok( sprintf ( "/diary/read/%s/%s", $user_A->name , $now_str ), '他人の記事が読める' );
        unlike( $mech->content,
            qr|<a href="/diary/write/$now_str"|,
            '編集ページへのリンクがない' );
    };

    subtest "My Access" => sub {
        $mech = create_mech( user=>$user_A);
        $mech->get_ok( sprintf ( "/diary/read/%s/%s", $user_A->name, $now_str ), '自分の記事が読める' );
        like( $mech->content,
            qr|<a href="/diary/write/$now_str"|,
            '編集ページへのリンクがある' );
    };

}

sub diary_write : Test(3) {
    my $mech;

    my $now = DateTime->now();
    my $now_str = DateTime::Format::MySQL->format_date($now);

    my $title = random_regex('test_title_\w{18}');
    my $content =  random_regex('test_content_\w{30}');

    my $user_A = create_user;
    my $diary = create_diary( user=>$user_A , date => $now, title => $title, content => $content );

    my $db = Intern::Diary::DBI::Factory->new;

    subtest 'Guest Access' => sub {
        $mech = create_mech;
        $mech->get_ok( '/diary/write' , '未ログインでも書き込みページにアクセスはできる' );
        $mech->title_is( 'Intern::Diary - Please Login', 'タイトルOK' );
    };

    subtest "User Access - Without Timestamp" => sub {
        $mech = create_mech( user=>$user_A);
        $mech->get_ok( '/diary/write' , 'ログインしている時に書き込みページにアクセスできる' );
        like( $mech->content,
            qr|<form .+? id="write_diary"|,
            '書き込みフォームが表示されている' );
        # 頑張ってフォーム書き込みをする
        $mech->submit_form( form_id=>'write_diary',
                            fields => +{ diary_title => $title, diary_content => $content } );
        ok( $mech->success, '日記を書く');

        # 書き込んだ日記の内容を確認するのにIntern::Diary::Service::Diary使ってるのはどうかと思うけども
        my $diary_new = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{ user => $user_A, date => $now } );
        is_deeply $diary_new, $diary, '書き込みたかった日記が書けている';
    };

    subtest "User Access - With Timestamp" => sub {
        $mech = create_mech( user=>$user_A);
        $mech->get_ok( sprintf("/diary/write/%s",$now_str ) , 'ログインしている時に書き込みページにアクセスできる' );

        my $title_new = random_regex('test_title_\w{18}');
        my $content_new =  random_regex('test_content_\w{30}');

        like( $mech->content,
            qr|<form .+? id="write_diary"|,
            '書き込みフォームが表示されている' );
        # 頑張ってフォーム書き込みをする
        $mech->submit_form( form_id=>'write_diary',
                            fields => +{ diary_title => $title_new, diary_content => $content_new } );
        ok( $mech->success, '日記を更新する');

        # 書き込んだ日記の内容を確認するのにIntern::Diary::Service::Diary使ってるのはどうかと思うけども
        my $diary_new = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{ user => $user_A, date => $now } );
        is $diary_new->title, $title_new, 'タイトルが編集できている';
        is $diary_new->content, $content_new, '本文が編集できている';

        # 記事を削除したい
        $mech->get( sprintf("/diary/write/%s",$now_str ) );
        like( $mech->content,
            qr|<form .+? id="delete_diary"|,
            '削除フォームが表示されている' );
        $mech->submit_form( form_id=>'delete_diary', );
        ok( $mech->success, '日記を削除する');
        my $diary_deleted = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{ user => $user_A, date => $now } );
        ok ( ! defined $diary_deleted, '日記が削除されている' );
    };

}


__PACKAGE__->runtests;

1;

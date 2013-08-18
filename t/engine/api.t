package t::Intern::Diary::Engine::API;

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
use JSON::XS;

use Intern::Diary::Service::Diary;

sub diary_list : Test(4) {
    my $mech;

    my $now = DateTime->now();
    my $now_str = DateTime::Format::MySQL->format_date($now);

    my $user = create_user;
    # 4件分エントリを作る
    my $diaries = [ map { create_diary( user=>$user , date => $now->subtract( days => 1 ) );  } (0..3) ] ;
    # jsonではこんな感じで帰ってきていてほしい
    # 全記事分作って各subtestで要るところだけ使う
    my $diaries_json = [ map { +{
        user_name => $user->name,
        title => $_->title,
        diary_id => DateTime::Format::MySQL->format_date($_->date),
        date => $_->date->ymd('/'),
        content => $_->content,
    } } @$diaries ];

    $mech = create_mech;

    subtest '全記事まとめてAPI取得' => sub {
        $mech->get_ok( sprintf ( "/API/diary_list/%s", $user->name ), 'Getが通る' );
        my $json = JSON::XS::decode_json $mech->content();
        is $json->{n_of_all}, scalar @$diaries , '件数一致';
#        use Data::Dumper; print Dumper $json;
        is_deeply $json->{entries}, $diaries_json , '内容一致';
    };

    subtest 'PAGEだけ指定してAPI取得' => sub {
        $mech->get_ok( sprintf ( "/API/diary_list/%s?page=2", $user->name ), 'Getが通る' );
        my $json = JSON::XS::decode_json $mech->content() ;
        is_deeply $json->{entries}, $diaries_json , 'PAGEだけ指定しても無視されて全部返ってくる';
    };

    subtest 'LIMITだけ指定してAPI取得' => sub {
        $mech->get_ok( sprintf ( "/API/diary_list/%s?limit=2", $user->name ), 'Getが通る' );
        my $json = JSON::XS::decode_json $mech->content() ;
        is $json->{n_of_all}, scalar @$diaries , '件数は全部';
        is_deeply $json->{entries}, [ @$diaries_json[0,1] ] , '内容一致';
    };

    subtest 'PAGEとLIMITを指定してAPI取得' => sub {
        $mech->get_ok( sprintf ( "/API/diary_list/%s?limit=2&page=2", $user->name ), 'Getが通る' );
        my $json = JSON::XS::decode_json $mech->content() ;
        is $json->{n_of_all}, scalar @$diaries , '件数は全部';
        is_deeply $json->{entries}, [ @$diaries_json[2,3] ] , '内容一致';
    };

}

__PACKAGE__->runtests;

1;

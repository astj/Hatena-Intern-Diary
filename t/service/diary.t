package t::Intern::Diary::Service::Diary;

use strict;
use warnings;
use utf8;
use lib 't/lib';

use parent 'Test::Class';

use Test::Intern::Diary;
use Test::Intern::Diary::Factory;

use Test::More;

use Intern::Diary::DBI::Factory;

use Intern::Diary::Model::User;
use DateTime;
use DateTime::Format::MySQL;

sub _require : Test(startup => 1) {
    my ($self) = @_;
    require_ok 'Intern::Diary::Service::Diary';
}

sub add_diary : Test(5) {
    my ($self) = @_;

    my $db = Intern::Diary::DBI::Factory->new;

    my $user = create_user;
    my $now = DateTime->now();

    my $diary = Intern::Diary::Service::Diary->add_diary( $db,
       +{ user => $user,
          date => $now,
          title => 'Title of a Day',
          content => 'Hatena Intern ha saikou ya!',
       }
    );

#    my $diary = $db->dbh('intern_diary')->select_row(q[
#SELECT * FROM diary WHERE user_id=:user_id AND date=:date
#    ],{user_id => $user->user_id, date => DateTime::Format::MySQL->format_date($now)});

    ok $diary;
    is $diary->{user_id}, $user->user_id, 'User ID match';
    is $diary->{date}, DateTime::Format::MySQL->format_date($now), 'Date match';
    is $diary->{title}, 'Title of a Day', 'Title match';
    is $diary->{content}, 'Hatena Intern ha saikou ya!', 'Content match';

}

sub find_diary_by_user : Test(3) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    my $user = create_user;
    my $now = DateTime->now();
    my $oldday = DateTime->from_epoch( epoch => 1000000 );

    my $diary_1 = create_diary(
      user=>$user,
      date => $now,
      title => 'Diary 1',
      content => 'こんてんと1'
    );
    my $diary_2 = create_diary(
      user=>$user,
      date => $oldday,
      title => 'Diary 2',
      content => 'Content 2'
    );

    my $diaries = Intern::Diary::Service::Diary->find_diary_by_user($db, {user=>$user});

    is scalar @$diaries, 2, '2件みつかった';
    is_deeply $diaries->[0], $diary_1,'1件目が新しい';
    is_deeply $diaries->[1], $diary_2, '2件目は古い';
}

sub update_diary_with_user_and_date : Test(2) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    my $user = create_user;
    my $now = DateTime->now();

    my $entry_old = create_diary(user => $user, date => $now);
#    Intern::Diary::Service::Diary->insert_diary( $db,
#     +{ user=>$user,
#        date => $now,
#        title => 'Diary 1',
#        content => 'Content 1',
#     }
#    );

    Intern::Diary::Service::Diary->update_diary_with_user_and_date( $db,
     +{ user => $user,
        date => $now,
        title => 'Modified Diary',
        content => 'Content is modified.',
     }
    );

    my $diary =  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ], +{ user_id=>$user->user_id , date=>DateTime::Format::MySQL->format_date($now) },
                                                               'Intern::Diary::Model::Diary');

    is $diary->title, 'Modified Diary', 'Title updated';
    is $diary->content, 'Content is modified.', 'Content updated';

}

sub delete_diary_with_user_and_date : Test(1) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    my $user = create_user;
    my $now = DateTime->now();

    my $diary = create_diary( user => $user, date => $now );

    Intern::Diary::Service::Diary->delete_diary_with_user_and_date($db,
                  +{ user => $user, date => $now} );

    my $diary_after =  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ], +{ user_id=>$user->user_id , date=>DateTime::Format::MySQL->format_date($now) },
                                                               'Intern::Diary::Model::Diary');

    is $diary_after, undef, 'Deleteした後はfindでヒットしない';

}

sub find_diary_by_user_and_date : Test(2){
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

# Helperがfind_diary_by_user_and_date使ってるからこのテストでは使っちゃダメ?
# と思ったけどBookmarkだと普通に使ってるんですね

    my $user = create_user;
    my $now = DateTime->now();

    create_diary(
        user => $user,
        date => $now,
        title => 'Title of a Day',
        content => 'Hatena Intern ha saikou desu',
    );

    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date($db,
                  +{ user => $user, date => $now} );

    my $diary2 = $db->dbh('intern_diary')->select_row(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ],{user_id => $user->user_id, date => DateTime::Format::MySQL->format_date($now)});

    is $diary->{title}, 'Title of a Day';
    is $diary->{content}, 'Hatena Intern ha saikou desu';

}

sub update_diary_with_id : Test(2) {
    my $self = shift;
    my $db = Intern::Diary::DBI::Factory->new();

    my $user = create_user;
    my $now = DateTime->now();

    my $diary = create_diary( user=>$user, date=>$now );

    Intern::Diary::Service::Diary->update_diary_with_id( $db,
     +{ diary_id => $diary->diary_id,
        title => 'Modified Diary',
        content => 'Content is modified.',
     }
    );

    my $entry =  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ], +{ user_id=>$user->user_id , date=>DateTime::Format::MySQL->format_date($now) },
                                                               'Intern::Diary::Model::Diary');

    is $entry->title, 'Modified Diary', 'Title updated';
    is $entry->content, 'Content is modified.', 'Content updated';
}

sub delete_diary_with_id : Test(1) {
    my $self = shift;

    my $db = Intern::Diary::DBI::Factory->new;

    my $user = create_user;
    my $now = DateTime->now();

    my $diary = create_diary( user => $user, date => $now );

    Intern::Diary::Service::Diary->delete_diary_with_id($db,
                  +{ diary_id => $diary->diary_id} );

    my $entry =  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ], +{ user_id=>$user->user_id , date=>DateTime::Format::MySQL->format_date($now) },
                                                               'Intern::Diary::Model::Diary');

    is $entry, undef, 'Deleteした後はfindでヒットしない';
}

# Insertのテスト書いてない

__PACKAGE__->runtests;

1;

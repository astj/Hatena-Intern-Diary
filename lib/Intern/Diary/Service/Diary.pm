package Intern::Diary::Service::Diary;
use strict;
use warnings;
use utf8;

use Carp;
use Intern::Diary::Util;

use DateTime;
use DateTime::Format::MySQL;

# Insert a diary
sub add_diary {
    my ($class, $db, $args) = @_;

    # 必須パラメータはなぁに
    my $user = Intern::Diary::Util->require_argument($args, 'user', 'Intern::Diary::Model::User');
    my $date = Intern::Diary::Util->require_argument($args, 'date', 'DateTime');
    my $title = $args->{title} // croak "required: title";
    my $content = $args->{content} // croak "required: content";

    # ToDo: 同じID/Dateの組が存在したときの例外

    # じゃあInsertにお願い
    $class->insert( $db,
     +{ user_id => $user->user_id,
        date => $date->ymd,
        title => $title,
        content => $content,
     }
    );

    # できたDiaryを返す
    return $class->find_diary_by_user_and_date( $db, +{ user => $user, date => $date } );

}

# Find Diary records with a certain userID
sub find_diary_by_user {
    my ($class, $db, $args) = @_;

    # 必須のパラメータ
    my $user = Intern::Diary::Util->require_argument($args, 'user', 'Intern::Diary::Model::User');

    # 探して返す
    return $db->dbh('intern_diary')->select_all_as(q[
SELECT * FROM diary
 WHERE user_id=:user_id
 ORDER BY date desc
    ], +{ user_id=>$user->user_id }, 'Intern::Diary::Model::Diary');

}

# Update a Diary record
sub update_diary_with_user_and_date {
    my ($class, $db, $args) = @_;

    # 必須パラメータはなぁに
    my $user = Intern::Diary::Util->require_argument($args, 'user', 'Intern::Diary::Model::User');
    my $date = Intern::Diary::Util->require_argument($args, 'date', 'DateTime');
    my $title = $args->{title} // croak "required: title";
    my $content = $args->{content} // croak "required: content";

    my $diary = $class->find_diary_by_user_and_date($db, +{user=>$user, date=>$date});

    # この関数はWrapperにすぎない
    $class->update_diary_with_id($db,
                                 +{ diary_id => $diary->diary_id, title => $title, content => $content });

}

# Delete a Diary record
sub delete_diary_with_user_and_date {
    my ($class, $db, $args) = @_;

    # 必須パラメータはなぁに
    my $user = Intern::Diary::Util->require_argument($args, 'user', 'Intern::Diary::Model::User');
    my $date = Intern::Diary::Util->require_argument($args, 'date', 'DateTime');

    my $diary = $class->find_diary_by_user_and_date($db, +{user=>$user, date=>$date});

    # この関数はWrapperにすぎない
    $class->delete_diary_with_id( $db,+{ diary_id => $diary->diary_id } );

}


# user/dateからdiaryを引いてくる
sub find_diary_by_user_and_date {
    my ($class, $db, $args) = @_;

    # 必須のパラメータ
    my $user = Intern::Diary::Util->require_argument($args, 'user', 'Intern::Diary::Model::User');
    my $date = Intern::Diary::Util->require_argument($args, 'date', 'DateTime');

    # こっちは1行だけ返す
    return my $diary =  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM diary WHERE user_id=:user_id AND date=:date
    ], +{ user_id=>$user->user_id , date=>DateTime::Format::MySQL->format_date($date) },'Intern::Diary::Model::Diary');

}

# DBIに薄皮被せただけのところ

# INSERT
sub insert {
    my ($class, $db, $args) = @_;

    my $user_id = $args->{user_id} // croak "required: user_id";
    my $date = $args->{date} // croak "required: date";
    my $title = $args->{title} // croak "required: title";
    my $content = $args->{content} // croak "required: content";

    # じゃあInsertしちゃう
    $db->dbh('intern_diary')->query(q[
INSERT INTO diary
 SET user_id=:user_id,
     date=:date,
     title=:title,
     content=:content
    ], +{user_id=>$user_id, date=>$date, title=>$title, content=>$content});

}


# 与えられたIDを持つdiaryのtitle/contentを更新する
sub update_diary_with_id {
    my ($class, $db, $args) = @_;

    $db->dbh('intern_diary')->query(q[
UPDATE diary SET title=:title, content=:content WHERE diary_id=:diary_id
    ], +{diary_id=>$args->{diary_id}, title=>$args->{title}, content=>$args->{content}});

}

# 与えられたIDを持つdiaryを削除する。
sub delete_diary_with_id {
    my ($class, $db, $args) = @_;

    $db->dbh('intern_diary')->query(q[
DELETE FROM diary WHERE diary_id=:diary_id
    ], +{diary_id=>$args->{diary_id}});

}


1;

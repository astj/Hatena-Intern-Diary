package Test::Intern::Diary::Factory;

use strict;
use warnings;
use utf8;

use Exporter::Lite;
our @EXPORT = qw(
    create_user
    create_diary
);

# Bookmarkのt/lib/Test/Intern/Bookmark/Factory.pmのほぼ丸コピなのは正直よくない

use String::Random qw(random_regex);
use DateTime;
use DateTime::Format::MySQL;

use Intern::Diary::Service::User;
use Intern::Diary::Service::Diary;

sub create_user {
    my %args = @_;
    my $name = $args{name} // random_regex('test_user_\w{15}');

    my $db = Intern::Diary::DBI::Factory->new;
    my $dbh = $db->dbh('intern_diary');
    $dbh->query(q[
        INSERT INTO user
          SET name = :name
    ], {
        name    => $name,
    });

    return Intern::Diary::Service::User->find_user_by_name($db, { name => $name });
}

sub create_diary {
    my %args = @_;
    my $title = $args{title} // random_regex('test_title_\w{15}');
    my $content = $args{content} // random_regex('test_diary_content_\w{15}');
    my $user = $args{user} // create_user;
    my $date = $args{date} // DateTime->now();

    my $db = Intern::Diary::DBI::Factory->new;
    my $dbh = $db->dbh('intern_diary');
    $dbh->query(q[
        INSERT INTO diary
      SET user_id = :user_id,
      date = :date,
      title = :title,
      content = :content
    ], {
        user_id => $user->user_id,
        date => $date->ymd(),
        title => $title,
        content => $content
    });

    return Intern::Diary::Service::Diary->find_diary_by_user_and_date($db, { user => $user, date => $date });
}


1;

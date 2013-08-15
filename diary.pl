#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib", glob "$FindBin::Bin/modules/*/lib";

use Pod::Usage;

use Encode;
#use Encode::Locale;

use DateTime;

use Intern::Diary::Config;
use Intern::Diary::DBI::Factory;
use Intern::Diary::Service::Diary;
use Intern::Diary::Service::User;

binmode STDOUT, ':encoding(utf-8)';

# if( $ARGV[0] eq うんたら )とかしか知らなかった
my %HANDLER = (
    add => \&add_diary,
    show => \&show_diary,
    list => \&list_diary,
    edit => \&edit_diary,
    delete => \&delete_diary,
);

# command
my $command = shift @ARGV || 'list';

# Work as Local
$ENV{INTERN_DIARY_ENV} = 'local';
my $db = Intern::Diary::DBI::Factory->new;

# Username
my $name = $ENV{USER};
my $user = Intern::Diary::Service::User->find_user_by_name( $db, +{ name => $name } );
unless ($user) {
    $user = Intern::Diary::Service::User->add_user( $db, +{ name => $name } );
}

my $handler = $HANDLER{ $command } || pod2usage;

$handler->($user, @ARGV);

exit 0;

sub add_diary {
    my ($user, $title) = @_;

    die 'required: title' unless defined $title;

    my $today = DateTime->now;

    # 今日のDiaryが既に存在していたらだめよ
    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{
        user => $user,
        date => $today, } );

    if( $diary ) {
        print q[Today's diary is already exists. try 'diary.pl edit' to edit.]."\n";
        exit;
    }

    print q[Write Today's Diary in 1 line: >];
    my $content = <STDIN>;
    chomp $content;

    $diary = Intern::Diary::Service::Diary->add_diary( $db, +{
      user => $user,
      date => $today,
      title => $title,
      content => $content } );

    print 'Wrote diary for '.$today->ymd."\n";
}

sub show_diary {
    my ($user, $diary_id) = @_;

    die 'required: id' unless defined $diary_id;

    my $date = DateTime::Format::MySQL->parse_date($diary_id);

    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{
        user => $user,
        date => $date, } );

    if( ! $diary ) {
        print 'Diary not found'."\n";
        exit;
    }

    my $title = $diary->title;
    my $content = $diary->content;

print <<"EOM";
id/date : $diary_id
Title   : $title
--------------------------------------------------------
$content
EOM

}

sub list_diary {
    my ($user) = @_;

    my $name = $user->name;

    my $diaries = Intern::Diary::Service::Diary->find_diary_by_user( $db, +{
        user => $user, } );

print <<"EOM";

$name 's diaries
------------------------
    date    |   title
------------------------
EOM

    foreach( @$diaries ) {
        my $date = DateTime::Format::MySQL->format_date($_->date);
        my $title = $_->title;
print <<"EOM";
 $date | $title
EOM
    }

print <<EOM;
------------------------

EOM

}

sub delete_diary {
    my ($user, $diary_id) = @_;

    die 'required: id' unless defined $diary_id;

    my $date = DateTime::Format::MySQL->parse_date($diary_id);

    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{
        user => $user,
        date => $date, } );

    if( ! $diary ) {
        print 'Diary not found'."\n";
        exit;
    }

    Intern::Diary::Service::Diary->delete_diary_with_user_and_date( $db, +{
        user => $user,
        date => $date, } );

    print 'Deleted diary for '.$date->ymd."\n";

}

sub edit_diary {
    my ($user, $did) = @_;

    die 'required: id' unless defined $did;

    my $date = DateTime::Format::MySQL->parse_date($did);

    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $db, +{
        user => $user,
        date => $date, } );

    if( ! $diary ) {
        print q[Diary not found. try './diary.pl add' instead.]."\n";
        exit;
    }

    print 'Current Diary is ...'."\n";

    my $title = $diary->title;
    my $content = $diary->content;

print <<"EOM";
id/date : $did
Title   : $title
--------------------------------------------------------
Body    :
$content
EOM

    print q[New Title? (Empty for keep original title) >];
    my $new_title = <STDIN>;
    chomp $new_title;
    if( length($new_title) ) { $title = $new_title; }

    print q[New Body? (Empty for keep original body) >];
    my $new_content = <STDIN>;
    chomp $new_content;
    if( length($new_content) ) { $content = $new_content; }

    $diary = Intern::Diary::Service::Diary->update_diary_with_user_and_date( $db, +{
      user => $user,
      date => $date,
      title => $title,
      content => $content } );

    print 'Edited diary for '.$date->ymd."\n";
}


__END__

=head1 NAME

diary.pl - コマンドラインで日記を書くためのツール。

=head1 SYNOPSIS

  $ ./diary.pl [action] [argument...]

=head1 ACTIONS

=head2 C<add>

  $ diary.pl add [title]

日記に記事を書きます。

=head2 C<list>

  $ diary.pl list

日記に投稿された記事の一覧を表示します。

=head2 C<edit>

  $ diary.pl edit [entry ID]

指定したIDの記事を編集します。

=head2 C<show>

  $ diary.pl show [entry ID]

指定したIDの記事を表示します。

=head2 C<delete>

  $ diary.pl delete [entry ID]

指定したIDの記事を削除します。

=cut

package Intern::Diary::Model::Diary;

use strict;
use warnings;

use Encode;
use utf8;

use Class::Accessor::Lite (
    ro => [qw( diary_id  user_id)],
    new => 1,
);

sub title {
    my $self = shift;
#    return $self->{_title} //= do {decode 'utf8', $self->{title} || ''};
    return $self->{_title} //= do {decode_utf8 $self->{title} || ''};
}

sub content {
    my $self = shift;
    return $self->{_content} //= do {decode_utf8 $self->{content} || ''};
}

use DateTime::Format::MySQL;

sub date {
    my $self = shift;

    return $self->{_date} //= do {
        my $dt = DateTime::Format::MySQL->parse_date($self->{date});
        $dt->set_time_zone('UTC'); # MySQLをパースした時点ではfloatらしひ
        $dt->set_formatter( DateTime::Format::MySQL->new );
        $dt;
    }
}

1;

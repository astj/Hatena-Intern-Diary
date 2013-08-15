package Intern::Diary::Util;

use strict;
use warnings;

use utf8;

use Carp;
use Sub::Name;

use DateTime;
use DateTime::Format::MySQL;

use Intern::Diary::Config;

sub datetime_from_db ($) {
    my $dt = DateTime::Format::MySQL->parse_datetime( shift );
    $dt->set_time_zone(config->param('db_timezone'));
    $dt->set_formatter( DateTime::Format::MySQL->new );
    $dt;
}

sub require_argument {
    my ($class, $args, $label, $object_name) = @_;
    my $obj = $args->{$label} // croak "required: $label";
    !$obj->isa($object_name) && croak "invalid object: $label";

    return $obj;
}

1;
__END__

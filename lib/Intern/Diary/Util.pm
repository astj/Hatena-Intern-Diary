package Intern::Diary::Util;

use strict;
use warnings;

use Carp;

sub require_argument {
    my ($class, $args, $label, $object_name) = @_;
    my $obj = $args->{$label} // croak "required: $label";
    !$obj->isa($object_name) && croak "invalid object: $label";

    return $obj;
}


1;

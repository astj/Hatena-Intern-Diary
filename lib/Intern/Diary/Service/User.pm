package Intern::Diary::Service::User;

use strict;
use warnings;
use utf8;

use Carp;
use Intern::Diary::Util;

sub find_user_by_name {
    my ($class, $db, $args) = @_;

    my $name = $args->{name} // croak "required: name";

    # こっちは1行だけ返す
    return  $db->dbh('intern_diary')->select_row_as(q[
SELECT * FROM user WHERE name=:name
    ], +{ name=>$name },'Intern::Diary::Model::User');

}

sub add_user {
    my ($class, $db, $args) = @_;

    my $name = $args->{name} // croak "required: name";

    # 既に該当userが存在していた時にどうこうするならこのタイミング

    # insertにおねがいする
    $class->insert($db, +{name=>$name});

    # 結果を返す
    return $class->find_user_by_name( $db, +{name=>$name });

}


# DBIに薄皮被せただけのところ

# INSERTするだけ
sub insert {
    my ($class, $db, $args) = @_;

    my $name = $args->{name} // croak "required: name";

    $db->dbh('intern_diary')->query(q[
INSERT INTO user
 SET name=:name
    ], +{name=>$name});
}

# UPDATEはやることがないから作ってない
sub update {
}

# DELETE
sub delete_by_id {
    my ($class, $db, $args) = @_;

    my $user_id = $args->{user_id} // croak "required: user_id";

    $db->dbh('intern_diary')->query(q[
DELETE FROM user
 WHERE user_id=:user_id
    ], +{user_id=>$user_id});

}

1;

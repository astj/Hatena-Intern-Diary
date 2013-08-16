package Intern::Diary::Engine::Index;

use strict;
use warnings;
use utf8;

sub default {
    my ($class, $c) = @_;

    # Loginしているなら自分のDiaryに
    if( defined $c->current_user ) {
        $c->redirect(sprintf "/diary/list/%s", $c->current_user->name);
    }
    # してないならログイン画面へ
    else {
        $c->redirect('/user/login');
    }
}

1;
__END__

package Intern::Diary::Engine::User;

use strict;
use warnings;
use utf8;

use Carp;

use Intern::Diary::Service::User;

# /user/login
# 失敗時にFormを出すことを考えるとGET/POSTの両方をこっちで処理したほうが多分いい
sub login_form {
    my ($class, $c) = @_;

    # 認証で使うこととか考えて、ログインに失敗したときに
    # $error_message->{user_name} = '名前を入力してください！' とか
    # $error_message->{password} = 'パスワードを入力してください！'とか
    my $error_message = {};

    # Login Params来てる?
    my $attempt_user_name = $c->req->parameters->{user_name};

    my $current_user;

    # 来てるならログインできるか試す
    if ( defined $attempt_user_name ) {
        $current_user = $c->current_user($attempt_user_name);

        if ( ! defined $current_user ) { $error_message->{user_name} = 'Login failed'; }
    }


    # 認証できていれば自分のDiaryに
    if( defined $c->current_user ) {
        $c->redirect(sprintf "/diary/list/%s", $c->current_user->name);
    }
    # してないならログイン画面を表示する
    else {
    # Give params to View
        $c->html('user_login.html', {
            page_title => 'Login' ,
            error_message => $error_message,
    });
    }

}

# /user/logout
sub logout {
    my ($class, $c) = @_;

    # ログアウトさせる
    $c->logout_user;

    $c->redirect('/');


}

1;
__END__

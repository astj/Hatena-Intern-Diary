package Intern::Diary::Context;

use strict;
use warnings;
use utf8;

use Intern::Diary::Request;
use Intern::Diary::Config;

use Carp ();
use Encode ();
use URI;
use URI::QueryParam;

use Class::Accessor::Lite::Lazy (
    rw_lazy => [ qw(request response route stash db) ],
    rw      => [ qw(env) ],
    new     => 1,
);

use Intern::Diary::Error;
use Intern::Diary::DBI::Factory;

use Intern::Diary::Service::User;

### Properties

sub from_env {
    my ($class, $env) = @_;
    return $class->new(env => $env);
}

sub _build_request {
    my $self = shift;

    return undef unless $self->env;
    return Intern::Diary::Request->new($self->env);
};

sub _build_response {
    my $self = shift;
    return $self->request->new_response(200);
};

sub _build_route {
    my $self = shift;
    return Intern::Diary::Config->router->match($self->env);
};

sub _build_stash { +{} };

*req = \&request;
*res = \&response;

### HTTP Response

sub render_file {
    my ($self, $file, $args) = @_;
    $args //= {};

    require Intern::Diary::View::Xslate;
    my $content = Intern::Diary::View::Xslate->render_file($file, {
        c => $self,
        %{ $self->stash },
        %$args
    });
    return $content;
}

sub html {
    my ($self, $file, $args) = @_;

    # Some Hooks
    ## Add 'current_user_name' to $args
    if ( defined $self->current_user ) {
        $args->{current_user_name} = $self->current_user->name;

        ## Add 'target_is_current' to $args
        if( defined $args->{target_user_name} ) {
            $args->{target_is_current} = 1 - abs($args->{current_user_name} cmp $args->{target_user_name});
        }
    }

    my $content = $self->render_file($file, $args);
    $self->response->code(200);
    $self->response->content_type('text/html; charset=utf-8');
    $self->response->content(Encode::encode_utf8 $content);
}

sub json {
    my ($self, $hash) = @_;

    require JSON::XS;
    $self->response->code(200);
    $self->response->content_type('application/json; charset=utf-8');
    $self->response->content(JSON::XS::encode_json($hash));
}

sub plain_text {
    my ($self, @lines) = @_;
    $self->response->code(200);
    $self->response->content_type('text/plain; charset=utf-8');
    $self->response->content(join "\n", @lines);
}

sub redirect {
    my ($self, $url) = @_;

    $self->response->code(302);
    $self->response->header(Location => $url);
}

sub error {
    my ($self, $code, $message, %opts) = @_;
    Intern::Diary::Error->throw($code, $message, %opts);
}

sub uri_for {
    my ($self, $path_query) = @_;
    my $uri = URI->new(config->param('origin'));
    $uri->path_query($path_query);
    return $uri;
}

### DB Access
sub _build_db {
    my ($self) = @_;
    return Intern::Diary::DBI::Factory->new;
}

sub dbh {
    my ($self, $name) = @_;
    return $self->db->dbh($name);
}

### astj
sub current_user {
    # なんも認証してない ;-D
    my ($self,$attempt_user_name) = @_;

    # 引数がある場合はそちらがキー
    # この場合はキャッシュしてるcurrent_userをクリアする
    if ( defined $attempt_user_name ) {
        delete $self->{_current_user};
    } else {
        $attempt_user_name = $self->env->{'psgix.session'}->{current_user_name};
    }

    my $current_user = $self->{_current_user} //= Intern::Diary::Service::User->find_user_by_name( $self->db,+{
        name => $attempt_user_name // ''
    } );

    # 認証できていればSessionに記録
    if ( defined $current_user ) { $self->env->{'psgix.session'}->{current_user_name} = $current_user->name; }

    return $current_user;
}

sub logout_user {
    my ($self) = @_;

    # セッションをクリアする
    delete $self->env->{'psgix.session'}->{current_user_name};

    # current_userのキャッシュをクリアする
    delete $self->{_current_user};
}

1;

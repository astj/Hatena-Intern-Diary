package Intern::Diary::Config::Route;

use strict;
use warnings;
use utf8;

use Router::Simple::Declare;

sub make_router {
    return router {
        connect '/' => {
            engine => 'Index',
            action => 'default',
        };

# この辺 用意されてたけど作ってない
#        connect '/user/list' => {
#            engine => 'User',
#            action => 'list',
#        };
        connect '/user/register' => {
            engine => 'User',
            action => 'register_form',
        };

# ここからastj

        # /user/login (GET/POST)
        connect '/user/login' => {
            engine => 'User',
            action => 'login_form',
        };

        # /user/logout
        connect '/user/logout' => {
            engine => 'User',
            action => 'logout',
        };

        # /diary/write
        # /diary/write/
        # /diary/write/YYYY-MM-DD
        # /diary/write/YYYY-MM-DD/
        connect qr{/diary/write(?:/(\d{4}-\d{2}-\d{2})/?)?} => {
            engine => 'Diary',
            action => 'write_article',
        } => { method => 'GET' };

        # /diary/write  (POST)
        # /diary/write/ (POST)
        connect qr{/diary/write/?} => {
            engine => 'Diary',
            action => 'post_article',
        } => { method => 'POST' };

        # /diary/delete (POST)
        # /diary/delete/ (POST)
        connect qr{/diary/delete/?} => {
            engine => 'Diary',
            action => 'delete_article',
        };

        # /diary/read/USERNAME/YYYY-MM-DD
        # /diary/read/USERNAME/YYYY-MM-DD/
        connect qr{/diary/read/(\w+)/(\d{4}-\d{2}-\d{2})/?} => {
            engine => 'Diary',
            action => 'show_article',
        };

        # /diary/list/USERNAME
        # /diary/list/USERNAME/
        connect qr{/diary/list/(\w+)/?} => {
            engine => 'Diary',
            action => 'list',
        };

# for js-ex

        # /api/diary_list
        # /api/diary_list/
        connect qr{/API/diary_list/(\w+)/?} => {
            engine => 'API',
            action => 'diary_list',
        };


    };
}

1;

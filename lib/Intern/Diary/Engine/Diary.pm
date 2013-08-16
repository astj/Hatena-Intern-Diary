package Intern::Diary::Engine::Diary;

use strict;
use warnings;
use utf8;

use Carp;

use Intern::Diary::Service::Diary;
use Intern::Diary::Service::User;

use DateTime;
use DateTime::Format::MySQL;

sub default {
    my ($class, $c) = @_;
    $c->redirect(sprintf "/diary/list/%s", $c->current_user->name);
}

# /diary/list/USERNAME
sub list {
    my ($class, $c) = @_;

    # 1ページあたりの表示数をとりあえずここで決めておく
    my $num_per_page = 4;

    # 負のページは受け付けない
    my $page = $c->req->parameters->{'page'} // 0;
    $page = $page > 0 ? $page : 1;
    # Nページ目に対応するEntry : LIMIT $num_per_page OFFSET (N-1)*$num_per_page
    my $offset = ($page-1)*$num_per_page;
    my $limit = $num_per_page;

    # Obtain Target User
    # routerがちゃんと仕事をすればこのcroakに来ることはないはず
    my $target_user_name = $c->req->route_parameters->{splat}->[0] // croak 'User name is neccessary';
    my $target_user = Intern::Diary::Service::User->find_user_by_name( $c->db,+{
        name => $target_user_name
    } );

    # Obtain Target Diaries
    # offsetで読み飛ばしてもSQL鯖はいったん読み込んでからSkipしているので、
    # 件数が増えてきたときのPeformanceとしてはおおざっぱに言って
    # 全部読む場合のCost要素( offset+limit以降のSQL鯖負担 + limit以外でObjが作られるPerl負担)
    # Offsetで読み飛ばすとき( Query用にcount(*)を取得するSQL負担)
    # これら2つのCompareになって、どっちがいいのか僕には分からないので全部取得します;-D
    my $diaries_filtered = Intern::Diary::Service::Diary->find_diary_by_user( $c->db, +{
        user => $target_user , offset => $offset , limit => $limit,
    } );

    my $n_of_diaries = Intern::Diary::Service::Diary->count_diary_by_user( $c->db, +{
        user => $target_user,
    } );

    use POSIX ('ceil');
    my $total_pages = ceil($n_of_diaries/$limit);

#    my $diaries_filtered = [ grep {defined} @{$diaries}[$offset..$offset+$limit-1]  ];

    # Give params to View
    $c->html('diary_list.html', {
        diaries => $diaries_filtered,
        total_pages => $total_pages,
        current_page => $page,
        target_user_name => $target_user_name,
        page_title => sprintf("%s", $target_user_name),
    });

}

# /diary/read/USERNAME/YYYY-MM-DD
sub show_article {
    my ($class, $c) = @_;

    # Obtain Target Date
    my $target_date_txt = $c->req->route_parameters->{splat}->[1] // croak 'Date is neccessary';
    my $target_date = DateTime::Format::MySQL->parse_date($target_date_txt);

    # Obtain Target User
    # routerがちゃんと仕事をすればこのcroakに来ることはないはず
    my $target_user_name = $c->req->route_parameters->{splat}->[0] // croak 'User name is neccessary';
    my $target_user = Intern::Diary::Service::User->find_user_by_name( $c->db,+{
        name => $target_user_name
    } );

    # Obtain Target Diary
    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $c->db, +{
        user => $target_user , date => $target_date
    } );

    # Give params to View
    $c->html('diary_list.html', {
        diaries => [$diary],
        target_user_name => $target_user_name,
        page_title => sprintf("%s - %s", $target_user_name, $target_date->ymd('/')),
    });

}

# /diary/write/(OPT:YYYY-MM-DD)
sub write_article {
    my ($class, $c) = @_;

    # Obtain Target Date
    # ここでは必須ではない
    my $target_date_txt = $c->req->route_parameters->{splat}->[0];
    my $target_date = defined $target_date_txt ? DateTime::Format::MySQL->parse_date($target_date_txt) : DateTime->now();

    # Obtain Target User (is Current User)
    my $target_user = $c->current_user;

    # その日の日記が既に存在するか調べる
    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $c->db, +{
        user => $target_user, date => $target_date
    });

    # Give params to View
    $c->html('diary_write.html', {
        diary => $diary,
        target_date => $target_date,
        target_user_name => $target_user->name,
        page_title => sprintf("%s - Write for %s", $target_user->name, $target_date->ymd('/')),
    });

}

# /diary/write POST
sub post_article {
    my ($class, $c) = @_;

    # Obtain Target User (is Current User)
    my $target_user = $c->current_user;

    # Obtain Target Diary's info
    ###  Date
    my $target_date_txt = $c->req->parameters->{diary_date} // croak 'Date is neccessary';
    my $target_date = defined $target_date_txt ? DateTime::Format::MySQL->parse_date($target_date_txt) : DateTime->now();
    ###  Title
    my $target_title = $c->req->parameters->{diary_title} // croak 'Title is neccessary';
    ###  content
    my $target_content = $c->req->parameters->{diary_content} // croak 'Content-Body is neccessary';


    # その日の日記が既に存在するか調べる
    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $c->db, +{
        user => $target_user, date => $target_date
    });

    # もし既に存在するならupdateする
    if( $diary ) {
        $diary = Intern::Diary::Service::Diary->update_diary_with_user_and_date( $c->db, +{
            user => $target_user,
            date => $target_date,
            title => $target_title,
            content => $target_content } );
    }
    # 存在しないなら新しくつくる
    else {
        $diary = Intern::Diary::Service::Diary->add_diary( $c->db, +{
            user => $target_user,
            date => $target_date,
            title => $target_title,
            content => $target_content } );
    }

    # 完成した記事にリダイレクトする
    # Give params to View
    $c->redirect( sprintf "/diary/read/%s/%s" , $target_user->name, $target_date->ymd('-') );
}

# /diary/write POST
sub delete_article {
    my ($class, $c) = @_;

    # Obtain Target User (is Current User)
    my $target_user = $c->current_user;

    # Obtain Target Diary's info
    ###  Date
    my $target_date_txt = $c->req->parameters->{diary_date} // croak 'Date is neccessary';
    my $target_date = defined $target_date_txt ? DateTime::Format::MySQL->parse_date($target_date_txt) : DateTime->now();

    # その日の日記が既に存在するか調べる
    my $diary = Intern::Diary::Service::Diary->find_diary_by_user_and_date( $c->db, +{
        user => $target_user, date => $target_date
    });

    # もし存在するならdeleteする
    if( $diary ) {
        Intern::Diary::Service::Diary->delete_diary_with_user_and_date( $c->db, +{
            user => $target_user,
            date => $target_date,
            } );
    }

    # 自分のトップにリダイレクトする
    # Give params to View
    $c->redirect( sprintf "/diary/list/%s" , $target_user->name );
}

1;
__END__

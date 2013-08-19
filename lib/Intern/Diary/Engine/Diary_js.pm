package Intern::Diary::Engine::Diary_js;

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
    # ページのクエリに関しては受け付けたいけどちょっと後回し
#    my $page = $c->req->parameters->{'page'} // 0;
#    $page = $page > 0 ? $page : 1;
    # Nページ目に対応するEntry : LIMIT $num_per_page OFFSET (N-1)*$num_per_page
#    my $offset = ($page-1)*$num_per_page;
#    my $limit = $num_per_page;

    # Obtain Target User
    # routerがちゃんと仕事をすればこのcroakに来ることはないはず
    my $target_user_name = $c->req->route_parameters->{splat}->[0] // croak 'User name is neccessary';
    my $target_user = Intern::Diary::Service::User->find_user_by_name( $c->db,+{
        name => $target_user_name
    } );

#    my $diaries_filtered = [ grep {defined} @{$diaries}[$offset..$offset+$limit-1]  ];

    # Give params to View
    $c->html('diary_list_js.html', {
#        current_page => $page,
        articles_per_page => $num_per_page,
        target_user_name => $target_user_name,
        page_title => sprintf("%s", $target_user_name),
    });

}

1;
__END__

package Intern::Diary::Engine::API;

use strict;
use warnings;
use utf8;

use Carp;

use Intern::Diary::Service::Diary;
use Intern::Diary::Service::User;

use DateTime;
use DateTime::Format::MySQL;

# /diary/list/USERNAME
sub diary_list {
    my ($class, $c) = @_;

    # Obtain Target User
    # routerがちゃんと仕事をすればこのcroakに来ることはないはず
    my $target_user_name = $c->req->route_parameters->{splat}->[0] // croak 'User name is neccessary';
    my $target_user = Intern::Diary::Service::User->find_user_by_name( $c->db,+{
        name => $target_user_name
    } );

    # 負のページは受け付けない
    my $page = $c->req->parameters->{'page'} // 0;
    $page = $page > 0 ? $page : 1;
    # Nページ目に対応するEntry : LIMIT $num_per_page OFFSET (N-1)*$num_per_page
    my $limit = $c->req->parameters->{'limit'};
#    my $offset = ($page-1)*$num_per_page;

    # LIMITとOFFSET
    # LIMITが未定義だったら全部取得するから空ハッシュ
    my $offset_params = $limit ? { limit => $limit , offset => ($page-1) * $limit } : {};

    # Obtain Target Diaries
    my $diaries = Intern::Diary::Service::Diary->find_diary_by_user( $c->db, +{
        user => $target_user , %$offset_params,
    } );

    my $n_of_diaries = Intern::Diary::Service::Diary->count_diary_by_user( $c->db, +{
        user => $target_user,
    } );

#    use POSIX ('ceil');
#    my $total_pages = ceil($n_of_diaries/$limit);

#    my $diaries_filtered = [ grep {defined} @{$diaries}[$offset..$offset+$limit-1]  ];

    # articlesをjsonで返すarrayにしとく
    my $json_entries = [ map {
        +{
            user_name => $target_user->name,
            title => $_->title,
            diary_id => DateTime::Format::MySQL->format_date($_->date),
            date => $_->date->ymd('/'),
            content => $_->content,
        }
    } @$diaries ];

    # jsonを返す
    $c->json( +{
        n_of_all => $n_of_diaries,
        entries => $json_entries,
    });

}

1;
__END__

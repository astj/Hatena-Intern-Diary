var current_page = 1;
var articles_per_page = 1; // ページ初期化の時にセットアップされるはずの値
var max_page = 1; // 最初のAjax取得時にセットアップされるはずの値
var on_updating = 0; // 更新途中なら1にセットされている
var target_user_name = ''; // ページ初期化の時にセットアップされるはず
$( function ($) {

        _.templateSettings = {
//            interpolate : /\{\{(.+?)\}\}/g ,
            escape : /\{\{(.+?)\}\}/g
        };
        var template = _.template( $('.article_template').html() );

  var set_view_loaded = function ( msg ) {

      // Page Num
      $('.current_page').text(current_page);
      $('.max_page').text(max_page);
      $('.nav_loading').html(msg).delay(1000).fadeOut(200, function() { $('.nav_pagenumber').fadeIn(200); });

  };

  var set_view_loading = function ( msg ) {

      $('.nav_loading').html(msg, function() { $('.nav_pagenumber').fadeIn(200, function() { $('.nav_loading').fadeOut(200)});  });

  };

  var replace_articles_with_page = function ( to_page ) {
    if (on_updating) { return 0; }
    on_updating = 1;
    set_view_loading('Now Loading...');
    var json = $.getJSON( '/API/diary_list/' + target_user_name + '?' + $.param( {
        page: to_page, limit: articles_per_page
    } ) )
        .done(function(data) {
            $('#article_list_body').children().detach();
            $.each( data.entries, function(index, value) {  $('#article_list_body').append( template(value) ); } );
            current_page = to_page;
            max_page = Math.ceil(data.n_of_all/articles_per_page);
            set_view_loaded('Load Completed');
        })
            .fail(function() { set_view_loaded('Page Load failed'); })
                .always(function() { on_updating = 0; });

  };

  $('.get_1st_page').click ( function (e){
    if( current_page !== 1) { replace_articles_with_page( 1 ); }
    return false;
  } );

  $('.get_prev_page').click ( function (e){
    replace_articles_with_page( (current_page > 1)  ? --current_page : 1 );
    return false;
  } );

  $('.get_last_page').click ( function (e){
    if( current_page !== max_page ) { replace_articles_with_page( max_page ); }
    return false;
  } );

  $('.get_next_page').click ( function (e){
    replace_articles_with_page( (current_page < max_page)  ? ++current_page : max_page );
    return false;
  } );

  // onLoadなタイミングで記事を読み込む
  replace_articles_with_page( 1 );

} );

//= require jquery
//= require bootstrap-sprockets
//= require_tree .

$( document ).ready(function() {
    $("a:not(.my-custom-link)").click( my.click_handler() );
    my.load_page();
    $("a:not(.my-custom-link)").unbind('click').click( my.click_handler() );

    if (SignedIn) {
        my_html.show_logout_form( my.get_auth_container() );
    }
    else {
        my_html.show_login_form( my.get_auth_container() );
    }

    $("a.my-with-hash-link").unbind('click').click( my.custom_link_with_hash_click );

    $('#my-nav-start-slideshow-link > a').click( my_navigation.start_slideshow );
    $('#my-nav-stop-slideshow-link > a').click( my_navigation.stop_slideshow );
});

$(window).on("popstate", function() {
    my.load_page();
});

$(window).scroll(function() {
    if( $(window).scrollTop() + $(window).height() + my.LOAD_ANOTHER_ITEMS_OFFSET >= $(document).height() ) {
        my.load_another_items();
    }
});


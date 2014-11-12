window.my_navigation = {
    set_foolscreen: function() {
        $('.my-nav-link').removeAttr('style').removeClass('my-disabled');
        $('.my-nav-text').removeAttr('style').removeClass('my-disabled');
        $('#my-image-size').removeAttr('style').removeClass('my-disabled');
        $('#my-nav-up2-link').hide().addClass('my-disabled');
    },

    unset_foolscreen: function() {
        $('.my-nav-link').hide().addClass('my-disabled');
        $('.my-nav-text').hide().addClass('my-disabled');
        $('#my-image-size').hide().addClass('my-disabled');
        $('#my-nav-up2-link').removeAttr('style').removeClass('my-disabled');
    },

    toggle_main: function( hash ) {
        if ( /^(album|date|tag)\/[^\/]+\/.+\.jpg$/.test(hash) ) {
            return; // image has more complex navigation
        }

        $('.my-shown-nav').removeClass('my-shown-nav').addClass('my-hidden-nav');
        if ( /^(album\/?)?$/.test(hash) ) {
            return; // no parrent
        }

        var up_level = get_parent_page(hash);
        $('.my-hidden-nav').removeClass('my-hidden-nav').addClass('my-shown-nav');
        $('.my-shown-nav > a').attr('href',
            get_absolute_location() + "#" + up_level
        );
    },

    select_menu_item: function( item_name ) {
        $('.navbar li.active').removeClass('active');
        $('li#my-menu-' + item_name ).addClass('active');
    },

    toggle_image: function( image ) {
        $('.my-nav-link').addClass('my-foolscreen-hidden-nav-item');
        $('.my-nav-text').removeClass('my-foolscreen-hidden-nav-item');

        var parent_hash = my.get_parent_hash();
        $('#my-nav-up-link > a').attr( 'href',
            get_absolute_location() + "#" + parent_hash
        );
        $('#my-nav-up-text').addClass('my-foolscreen-hidden-nav-item')
        $('#my-nav-up-link').removeClass('my-foolscreen-hidden-nav-item');

        var nearest = my.get_image_prev_next( image.name );
        if ( nearest.prev ) {
            $('#my-nav-prev-link > a').attr( 'href',
                get_absolute_location() + "#" + nearest.prev
            );
            $('#my-nav-prev-text').addClass('my-foolscreen-hidden-nav-item')
            $('#my-nav-prev-link').removeClass('my-foolscreen-hidden-nav-item');
        }
        if ( nearest.next ) {
            $('#my-nav-next-link > a').attr( 'href',
                get_absolute_location() + "#" + nearest.next
            );
            $('#my-nav-next-text').addClass('my-foolscreen-hidden-nav-item')
            $('#my-nav-next-link').removeClass('my-foolscreen-hidden-nav-item');

            this.toggle_slideshow();
        }
    },

    go_to_next_page: function() {
        $('#my-nav-next-link:not(.my-disabled):not(.my-foolscreen-hidden-nav-item) > a').click();
    },

    go_to_prev_page: function() {
        $('#my-nav-prev-link:not(.my-disabled):not(.my-foolscreen-hidden-nav-item) > a').click();
    },

    go_to_upper_page: function() {
        link = $('#my-nav-up2-link:not(.my-disabled):not(.my-hidden-nav) > a');
        if ( link.length == 0 ) {
            link = $('#my-nav-up-link:not(.my-disabled):not(.my-foolscreen-hidden-nav-item) > a');
        }
        link.click();
    },

    toggle_slideshow: function() {
        if ( this._slideshow_timer == undefined ) {
            $('#my-nav-start-slideshow-link').removeClass('my-foolscreen-hidden-nav-item');
        }
        else {
            $('#my-nav-stop-slideshow-link').removeClass('my-foolscreen-hidden-nav-item');
        }
    },

    _slideshow_timer: undefined,
    start_slideshow: function() {
        $('#my-nav-stop-slideshow-link').removeClass('my-foolscreen-hidden-nav-item');
        $('#my-nav-start-slideshow-link').addClass('my-foolscreen-hidden-nav-item');
        var slideshow_next = function() {
            if ( $('#my-nav-next-link').is(':visible') ) {
                my_navigation.go_to_next_page();
            }
            else {
                my_navigation.stop_slideshow();
            }
        };
        my_navigation._slideshow_timer = setInterval( slideshow_next, SlideshowTimeout );
        return false;
    },
    stop_slideshow: function() {
        if ( my_navigation._slideshow_timer != undefined ) {
            if ( $('#my-nav-next-link').is(':visible') ) {
                $('#my-nav-start-slideshow-link').removeClass('my-foolscreen-hidden-nav-item');
            }
            $('#my-nav-stop-slideshow-link').addClass('my-foolscreen-hidden-nav-item');
            clearInterval( my_navigation._slideshow_timer );
            my_navigation._slideshow_timer = undefined;
        }
        return false;
    },
};

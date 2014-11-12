window.my = {
    get_items_container: function() {
        return $( '.my-content' );
    },

    _load_page_by_hash: function( hash ) {
        if ( hash == undefined || hash == null || hash == '' ) {
            hash = 'album';
        }
        this._loading_items = true;

        var body = this.get_items_container();
        body.html( I18n.loading );
        my_navigation.unset_foolscreen();
        my_navigation.toggle_main( hash );
        my_navigation.select_menu_item( hash.split('/')[0] );

        this._get_page_by_hash( hash,
            function( data ) {
                var title = ( data.self != undefined )
                    ? data.self.title
                    : get_page_title(hash);
                my_html.new_page( title );

                if ( data.self &&  SignedIn ) {
                    if ( data.self.protected != undefined ) {
                        $('#my-data-keeper').attr('data-protected', data.self.protected );
                    }
                    if ( data.self.hidden != undefined ) {
                        $('#my-data-keeper').attr('data-hidden', data.self.hidden );
                    }
                    if ( data.self.folder != undefined ) {
                        $('#my-data-keeper').attr('data-folder', data.self.folder );
                        if ( data.self.thumb != undefined && /^[^\/]+\/[^\/]+$/.test(data.self.thumb) ) {
                            var parts = data.self.thumb.split('/');
                            var value = data.self.folder ? parts[0] : parts[1];
                            $('#my-data-keeper').attr('data-thumb', value );
                        }
                        else {
                            $('#my-data-keeper').attr('data-thumb', '' );
                        }
                    }
                    if ( data.self.added != undefined ) {
                        $('#my-data-keeper').attr('data-date-added', data.self.added );
                    }
                }

                var code = data.code;
                if ( code == 200 ) {
                    var cb;
                    var items = data.items;
                    if ( items == undefined ) { // image
                        my_html.show_image( body, data.self, data.tags );
                        cb = function() {
                            my_html.breadcrumb();
                            my_navigation.toggle_image( data.self );
                            my_admin.show_admin_panel();
                        };
                    }
                    else {
                        if ( ReverseLists && items.length > 0 && data.self != undefined ) {
                            items = items.reverse();
                        }
                        my._next_item = 0;
                        my._loading_items = false;
                        my._current_items = items;
                        my._load_items(items);
                        cb = function() {
                            my_html.breadcrumb();
                        };
                    }
                    my._current_items = items;
                    my._add_page_to_stack( hash, data.self, data.items, cb, false );
                    my._current_items = null;
                }
                else {
                    var message = null;
                    if ( data.error ) {
                        message = data.error;
                    }
                    else if ( code == 404 ) {
                        message = I18n.error.not_found;
                    }
                    else if ( code == 403 ) {
                        var cb = function() {
                            if ( !Devel ) {
                                force_https(); // may never returns
                            }
                            my_html.show_auth_form( data.self.name, data.password_for )
                        };
                        my._current_items = [];
                        my._add_page_to_stack( hash, data.self, [], cb, true );
                        my._current_items = null;
                        return;
                    }
                    else {
                        message = I18n.error.internal_error;
                    }
                    my_html.show_error_message( message, data );
                }
            },
            function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        );
    },

    _load_page_by_url: function(url) {
        var hash = /^#/.test(url)
            ? url.substring(1)
            : extract_hash(url);
        return this._load_page_by_hash(hash);
    },

    load_page: function() {
        this._load_page_by_hash( get_hash_location() );
    },

    click_handler: function() {
        return function() {
            history.pushState( {}, '', $(this).attr("href") );
            my._load_page_by_url( $(this).attr("href") );
            return false;
        };
    },

    _get_page_by_hash: function( hash, onok, onfail ) {
        var new_page = get_absolute_location() + encodeURI(hash) + '.json';
        $.get( new_page, onok ).fail( onfail );
    },

    _page_stack: [],
    _clear_page_stack: function() {
        this._page_stack = [];
    },
    _add_page_to_stack: function( hash, item, children, onfinish, supress_errors ) {
        var use_onfinish = true;
        if ( this._page_stack.length ) {
            var from_page = null;
            for ( var i=this._page_stack.length-1; i>=0; i-- ) {
                var cur_item = this._page_stack[i];
                var rx = new RegExp( '^' + RegExp.escape(cur_item.hash) + '[/:]' );
                if ( /^image\//.test(cur_item.hash) ) {
                    if ( /^image\//.test(hash) ) {
                        this._page_stack.pop();
                     }
                     else {
                        from_page = this._page_stack.pop();
                     }
                }
                else if ( hash == cur_item.hash ) {
                    this._page_stack.pop();
                }
                else if ( /^image\//.test(hash) || rx.test(hash) ) {
                    break;
                }
                else {
                    from_page = this._page_stack.pop();
                }
            }
            if ( from_page && from_page.item ) {
                this.scroll_to( 'item-' + get_escaped_id(from_page.item) );
            }
        }
        else {
            var parent_hash = get_parent_page(hash);
            if ( parent_hash ) {
                var onok = function( data ) {
                    var code = data.code;
                    if ( code == 200 ) {
                        my._page_stack.unshift( { hash: parent_hash, item: data.self, children: data.items, } );
                    }
                    else if ( !supress_errors ) {
                        my_html.show_error_message( I18n.error.internal_error, data );
                    }

                    parent_hash = get_parent_page(parent_hash);
                    if ( parent_hash ) {
                        my._get_page_by_hash( parent_hash, onok, onfail );
                    }
                    else if (onfinish) {
                        onfinish();
                    }
                };
                var onfail = function( jqXHR, textStatus, errorThrown ) {
                    if ( !supress_errors ) {
                        my_html.show_error_message( I18n.error.internal_error, textStatus );
                    }
                    if (onfinish) onfinish();
                }
                my._get_page_by_hash( parent_hash, onok, onfail );
            }
            use_onfinish = false;
        }

        this._page_stack.push( { hash: hash, item: item, children: children, } );
        if ( use_onfinish && onfinish ) onfinish();
    },

    get_parent_hash: function() {
        if ( this._page_stack.length < 2 ) {
            return '';
        }
        return this._page_stack[ this._page_stack.length - 2 ].hash;
    },

    get_image_prev_next: function( image_name ) {
        if ( this._page_stack.length < 2 ) {
            return {};
        }
        var siblings = this._page_stack[ this._page_stack.length - 2 ].children;
        var idx = -1;
        for ( var i in siblings ) {
            if ( siblings[i].name == image_name ) {
                idx = +i;
                break;
            }
        }
        if ( idx < 0 ) {
            return {};
        }

        var parent_page = get_parent_page( get_hash_location() );

        var prev = null;
        if ( idx > 0 ) {
            prev = parent_page + '/' + siblings[idx-1].name;
        }

        var next = null;
        if ( idx < siblings.length - 1 ) {
            next = parent_page + '/' + siblings[idx+1].name;
        }

        return { prev: prev, next: next };
    },

    get_breadcrump: function() {
        var result = [];
        for ( var i in this._page_stack ) {
            var item = this._page_stack[i];
            var title = ( item.item != undefined )
                ? item.item.title
                : get_page_title(item.hash);
            result.push( { hash: item.hash, title: title, } );
        }
        return result;
    },

    _current_items: null,
    _get_current_items: function() {
        if ( this._current_items ) {
            return this._current_items;
        }
        else if ( this._page_stack.length ) {
            return this._page_stack[ this._page_stack.length - 1 ].children || [];
        }
        return [];
    },

    SCROLL_OFFSET_SHIFT: -80,
    scroll_to: function(item_id) {
        while (true) {
            var offset = $( '#' + item_id ).offset();
            if (offset) {
                $('html, body').animate({
                    scrollTop: offset.top + this.SCROLL_OFFSET_SHIFT
                }, 400);
                break;
            }

            if ( !this._load_items() ) {
                break;
            }
        }
    },

    LOAD_ANOTHER_ITEMS_OFFSET: 10,
    _next_item: 0,
    _loading_items: false,
    _load_items: function(items) {
        if ( this._loading_items ) {
            return;
        }
        this._loading_items = true;

        if ( !items || items.length == 0 ) {
            items = this._get_current_items();
            if ( !items || items.length == 0 ) {
                my_admin.show_admin_panel();
                return;
            }
        }

        var get_max_left = function() {
            var values = $.map(
                $(".my-item"),
                function( el, index ) {
                    return el.offsetLeft;
                }
            );
            return Math.max.apply(null, values);
        };

        var body = this.get_items_container();
        var overflow = false;
        var max_left = -1;
        var loaded_count = 0;
        var has_tail_space = true;
        for ( var i = this._next_item; i < items.length; i++ ) {
            var item = my_html.append_item( body, items[i] );
            loaded_count++;
            if ( item && !item.images_count ) {
                if (overflow) {
                    if ( max_left <= item[0].offsetLeft ) {
                        has_tail_space = false;
                        break;
                    }
                }
                else if ( $("body").height() > $(window).height() ) {
                    overflow = true;
                    max_left = get_max_left();
                }
            }
            else {
                has_tail_space = false;
            }
        }
        this._next_item = i + 1;
        if ( max_left == -1 ) {
            max_left = get_max_left();
        }

        if ( loaded_count && has_tail_space ) {
            var stubs_count = 0;
            var real_items_top = $(body).children().last()[0].offsetTop;
            while (1) {
                stubs_count++;
                var item = my_html.append_stub_item(body);
                if ( real_items_top < item[0].offsetTop ) {
                    item.hide();
                    break;
                }
                if ( max_left <= item[0].offsetLeft + item[0].offsetWidth/20 ) {
                    break;
                }
                else if ( stubs_count >= items.length ) {
                    break; // печаль...
                }
            }
        }
        if ( loaded_count && this._next_item >= items.length ) {
            my_admin.show_admin_panel();
        }
        else {
            this._loading_items = false;
        }

        return loaded_count;
    },
    load_another_items: function() {
        this._load_items();
    },

    album_authentify: function( album, password ) {
        var url = get_absolute_location() + 'album/' + encodeURI(album) + '/auth.json';
        $.ajax({
            type: 'post',
            url: url,
            data: { password: password },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    my._clear_page_stack();
                    my.load_page();
                }
                else if ( data.code == 403 ) {
                    my_html.show_error_message( I18n.error.wrong_password );
                }
                else {
                    my_html.show_error_message( I18n.error.internal_error, data );
                }
            },
            fail: function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        });
    },

    get_auth_container: function() {
        return $('#my-auth-form')[0];
    },

    authentify: function( login, password ) {
        var url = get_absolute_location() + 'login.json'; // TODO https
        $.ajax({
            type: 'post',
            url: url,
            data: { login: login, password: password },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    location.reload(); // never returns
                }
                else if ( data.error ) {
                    my_html.show_error_message( data.error );
                }
                else {
                    my_html.show_error_message( I18n.error.internal_error, data );
                }
            },
            fail: function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        });
    },

    sign_out: function() {
        var url = get_absolute_location() + 'logout.json';
        $.ajax({
            type: 'post',
            url: url,
            data: {},
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    location.reload(); // never returns
                }
                else if ( data.error ) {
                    my_html.show_error_message( data.error );
                }
                else {
                    my_html.show_error_message( I18n.error.internal_error, data );
                }
            },
            fail: function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        });
    },

    custom_link_with_hash_click: function() {
        var href = $(this).attr("href") + '?hash=' + get_hash_location();
        $(this).attr( "href", href );
        return true;
    },
};


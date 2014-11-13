window.my_admin = {
    item_title_click: function(e) {
        if ( $(e.target).parent().hasClass('my-selected') ) {
            $(e.target).parent().removeClass('my-selected');
        }
        else {
            $(e.target).parent().addClass('my-selected');
        }
        my_html.update_selected_count();
    },

    show_admin_panel: function() {
        if (!SignedIn) return;
        var hash = get_hash_location();

        var is_album = /^album(\/[^\/]+)?\/?$/.test(hash);
        var is_image = /^(album|date|tag)\/[^\/]+\/.+$/.test(hash);

        var item_body = undefined;
        var items_list_body = undefined;
        if ( is_album ) {
            item_body = my_html.get_edit_album_form();
        }
        else if ( is_image ) {
            item_body = my_html.get_edit_image_form();
        }

        if ( !is_image && !/^(date|tag)\/?$/.test(hash) ) {
            items_list_body = my_html.get_edit_images_form();
        }

        if ( item_body == undefined && items_list_body == undefined ) {
            return;
        }

        var panels = [];
        if ( item_body != undefined ) {
            panels.push(
                my_html.get_new_panel(
                    $('<span/>', { text: I18n.admin.current_item, }),
                    item_body
                )
            );
        }
        if ( items_list_body != undefined ) {
            panels.push(
                my_html.get_new_panel(
                    $('<span/>', {
                        text: I18n.admin.selected_items,
                        title: I18n.admin.select_items_hint,
                    }).append(
                        ' (',
                        $('<span/>', {
                            id: "my-selected-count",
                            text: '0',
                        }),
                        ')'
                    ),
                    items_list_body
                )
            );
        }

        $('<div/>', {
            "class": 'col-sm-12 my-admin-panel',
        }).append( panels ).appendTo( my.get_items_container() );
    },

    edit_item: function(params) {
        var request_params = {};
        for ( var k in params ) {
            request_params[ "modified[" + k + "]" ] = params[k];
        }
        var url = get_absolute_location() + get_hash_location() + '/update.json';
        $.ajax({
            type: 'post',
            url: url,
            data: request_params,
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    my.load_page();
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

    set_items_title: function( items_list, title, item_type, onok ) {
        if ( items_list.length < 1 ) {
            alert(I18n.error.no_items_selected);
            return;
        }
        else if ( title == "" ) {
            alert(I18n.error.empty_title_specified);
            return;
        }
        else if ( item_type == undefined || item_type == null || item_type == "" ) {
            alert(I18n.error.internal_error);
            return;
        }
        else if ( item_type != 'image' ) {
            alert(I18n.error.only_images_supported);
            return;
        }
        this._update_items( items_list, item_type, { title: title }, onok );
    },

    ITEMS_BULK_COUNT: 20,
    _update_items: function( items_list, item_type, fields, onok ) {
        var high_bound = this.ITEMS_BULK_COUNT;
        if ( high_bound > items_list.length ) {
            high_bound = items_list.length;
        }
        var request_params = {
            items_list: items_list.slice( 0, high_bound ).join(','),
        };
        for ( var k in fields ) {
            request_params[ "modified[" + k + "]" ] = fields[k];
        }
        var url = get_absolute_location() + encodeURI(item_type) + '/update_list.json';
        $.ajax({
            type: 'post',
            url: url,
            data: request_params,
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    if ( high_bound < items_list.length ) {
                        my_admin._update_items(
                            items_list.slice( high_bound ),
                            item_type, fields, onok
                        );
                    }
                    else if ( onok ) {
                        return onok();
                    }
                    else {
                        my.load_page();
                    }
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

    load_all_albums_list: function(cb) {
        var new_page = get_absolute_location() + 'album/list_all.json';
        $.get( new_page,
            function( data ) {
                var code = data.code;
                if ( code == 200 ) {
                    cb( data.items );
                }
                else if ( data.error ) {
                    message = data.error;
                }
                else {
                    my_html.show_error_message( I18n.error.internal_error, data );
                }
            }
        ).fail(
            function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        );
    },

    create_album: function( fields, onok ) {
        var request_params = {};
        for ( var k in fields ) {
            request_params[ "new[" + k + "]" ] = fields[k];
        }
        var url = get_absolute_location() + 'album/create.json';
        $.ajax({
            type: 'post',
            url: url,
            data: request_params,
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    onok();
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

    delete_items: function( item_type, items_list, onok ) {
        var url = get_absolute_location() + encodeURI(item_type) +
            '/' + encodeURI(items_list.shift()) + '/delete.json';
        $.ajax({
            type: 'post',
            url: url,
            data: {},
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    if ( items_list.length > 0 ) {
                        my_admin.delete_items(
                            item_type, items_list, onok
                        );
                    }
                    else if ( onok ) {
                        return onok();
                    }
                    else {
                        my.load_page();
                    }
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

    move_items: function( item_type, items_list, destination_album, onok ) {
        if ( items_list.length < 1 ) {
            alert(I18n.error.no_items_selected);
            return;
        }
        else if ( destination_album == "" ) {
            alert(I18n.error.empty_album_specified);
            return;
        }
        else if ( item_type == undefined || item_type == null || item_type == "" ) {
            alert(I18n.error.internal_error);
            return;
        }
        else if ( item_type != 'image' ) {
            alert(I18n.error.only_images_supported);
            return;
        }
        this._update_items( items_list, item_type, { album: destination_album }, onok );
    },

    assign_tag: function( item_type, items_list, tag, onok ) {
        if ( items_list.length < 1 ) {
            alert(I18n.error.no_items_selected);
            return;
        }
        else if ( tag == "" ) {
            alert(I18n.error.empty_tag_specified);
            return;
        }
        else if ( item_type == undefined || item_type == null || item_type == "" ) {
            alert(I18n.error.internal_error);
            return;
        }
        else if ( item_type != 'image' ) {
            alert(I18n.error.only_images_supported);
            return;
        }
        this._update_items( items_list, item_type, { tag: tag }, onok );
    },

    remove_image_tag: function( tag, onok ) {
        var url = get_absolute_location() + get_hash_location() + '/remove_tag.json';
        $.ajax({
            type: 'post',
            url: url,
            data: { tag: tag },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    if ( onok ) {
                        return onok();
                    }
                    else {
                        my.load_page();
                    }
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

    set_as_image_of_a_day: function( onok ) {
        var url = get_absolute_location() + get_hash_location() + '/image_of_a_day.json';
        $.ajax({
            type: 'post',
            url: url,
            data: {},
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(data) {
                if ( data.code == 200 ) {
                    if ( onok ) {
                        return onok();
                    }
                    else {
                        my.load_page();
                    }
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
};


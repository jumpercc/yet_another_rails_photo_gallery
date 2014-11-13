window.my_html = {
    TAG_BOUNDARIES: [ 8, 16, 32, 64, 128, 256, 512, 1024 ],

    append_a_tag: function( container, tag ) {
        var hash = "tag/" + tag.name;
        var klass = this.TAG_BOUNDARIES[ this.TAG_BOUNDARIES.length - 1 ];
        for ( var i in this.TAG_BOUNDARIES ) {
            if ( tag.images_count < this.TAG_BOUNDARIES[i] ) {
                klass = this.TAG_BOUNDARIES[i];
                break;
            }
        }
        klass = "my-tag-" + klass;

        $('<a/>', {
            "class": klass,
            href: get_absolute_location() + "#" + hash,
            text: tag.name + " ",
            id: 'item-' + get_escaped_id(tag)
        }).appendTo( container );
    },

    _append_item_tmpl:
'<div class="{{class}}" id="{{id}}" data-name="{{data_name}}" data-type="{{data_type}}">\
    <div class="my-title"{{#admin}} onclick="my_admin.item_title_click(event)"{{/admin}}>{{title}}</div>\
    <a href="{{href}}">\
        <img src="{{img_src}}" alt="{{title}}" title="{{title}}" />\
    </div>\
</div>',
    append_item: function( container, item ) {
        var img = null;
        var title = null;
        var url = null;
        var is_folder = false;
        var is_album = true;
        var data_type = "";
        if ( item.day != undefined ) {
            img = "/albums/thumbs/" + item.album + "/" + item.name;
            title = item.day;
            url = "date/" + item.day;
        }
        else if ( item.album != undefined ) {
            is_album = false;
            img = "/albums/thumbs/" + item.album + "/" + item.name;
            title = item.title;
            url = get_hash_location() + "/" + item.name;
            data_type = "image";
        }
        else if ( item.protected != undefined ) {
            url = "album/" + item.name;
            title = item.title;
            is_folder = item.folder;
            data_type = "album";
            if ( item.thumb ) {
                img = "/albums/thumbs/" + item.thumb;
            }
            else if ( item.protected ) {
                img = "/protected.png";
            }
            else {
                img = "/image_stub.png";
            }
        }
        else if ( item.images_count != undefined ) {
            return this.append_a_tag( container, item );
        }
        else {
            this.report_error( "unexpected item", item );
            return;
        }

        if ( /^\s*$/.test(title) ) {
            title = '-';
        }

        var item_html = Mustache.render( my_html._append_item_tmpl, {
            "class": "my-item" + ( is_folder ? ' my-folder-album' : ( is_album ? ' my-album' : '' ) ),
            id: 'item-' + get_escaped_id(item),
            data_name: item.name,
            data_type: data_type,
            href: get_absolute_location() + "#" + url,
            title: title,
            img_src: img,
            admin: SignedIn ? 1 : null,
        });
        return $(item_html).appendTo(container);
    },

    append_stub_item: function(container) {
        return $('<div/>', {
            "class": "my-item my-item-stub",
        }).append(
            $('<div/>', {
                "class": "my-title",
                html: '&nbsp;',
            })
        ).appendTo( container );
    },

    show_image: function( container, image, tags_list ) {
        my_navigation.set_foolscreen();
        container = $('<div/>').appendTo(container);

        var src = '/albums/' + ImageSize + '/' + image.album + '/' + image.name;
        $('<img/>', {
            src:   src,
            alt:   image.title,
            title: image.title,
            "class": "my-big-image",
        }).appendTo( container ).click( my_navigation.go_to_next_page );

        var tags_div = $('<div class="image-tags"/>').appendTo( container );
        for ( var i in tags_list ) {
            var tag = tags_list[i];
            $('<a/>', {
                href: get_absolute_location() + "#tag/" + tag.name,
                text: tag.name,
            }).appendTo(tags_div);
            if (SignedIn) {
                $('<a/>', {
                    "class": "btn btn-danger btn-xs active my-custom-link",
                    role: "button",
                    text: 'X',
                    title: I18n.admin.delete + ' "' + tag.name + '"',
                    "data-tag": tag.name,
                }).appendTo(tags_div).click(function(e) {
                    var tag = $(e.target).attr("data-tag");
                    my_admin.remove_image_tag( tag );
                    return false;
                });
            }
        }

        if ( image.photographer != null && image.photographer != "" ) {
            container.append( $('<div/>', {
                "id": 'my-photographer',
                text: I18n.photographer + ": " + image.photographer,
            }) );
        }
    },

    _show_message_tmpl:
'<div class="alert alert-{{type}} alert-dismissible" role="alert">\
  <button type="button" class="close"\
    data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">{{I18n.admin.close}}</span></button>\
  {{message}}\
</div>',
    _show_message: function( text, type ) {
        my.get_items_container().prepend(
            Mustache.render( my_html._show_message_tmpl, {
                I18n: I18n,
                message: text,
                type: type,
            })
        );
    },

    show_error_message: function( text, extra ) {
        this._show_message( text, 'danger' );
        this.report_error( text, extra );
    },

    show_ok_message: function( text ) {
        this._show_message( text, 'success' );
    },

    report_error: function( text, extra ) {
        // TODO
        // ingnore some errors
        // send stacktrace
    },

    _show_auth_form_tmpl:
'<form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return my_html.auth_form_onsubmit(event)">\
    <div class="form-group">\
        <div class="col-sm-offset-4 col-sm-3">\
            <input id="my-album-auth-name" type="text" class="hidden" name="user_fake" value="{{password_for}}" />\
            <input id="my-album-auth-password" type="password" name="password"\
                placeholder="{{I18n.auth_form.enter_password}}" class="form-control" />\
        </div>\
        <div class="col-sm-1">\
            <input type="submit" value="{{I18n.auth_form.submit}}" class="btn btn-success btn-block" />\
        </div>\
    </div>\
</form>',
    show_auth_form: function( album, password_for ) {
        my.get_items_container().append(
            Mustache.render( my_html._show_auth_form_tmpl, {
                I18n: I18n,
                album: album,
                password_for: password_for,
            })
        );
    },
    auth_form_onsubmit: function() {
        var album = $('#my-album-auth-name').val();
        var password = $('#my-album-auth-password').val();
        my.album_authentify( album, password );
        return false;
    },

    _show_login_form_tmpl:
'<form method="POST" action="#" role="form" onsubmit="return my_html.login_form_onsubmit(event)">\
    <div class="form-group">\
        <input id="my-auth-login" type="text" name="user" placeholder="{{I18n.auth_form.login}}" class="form-control" />\
    </div>\
    <div class="form-group">\
        <input id="my-auth-password" type="password" name="password" placeholder="{{I18n.auth_form.password}}" class="form-control" />\
    </div>\
    <div class="form-group">\
        <input type="submit" value="{{I18n.auth_form.submit}}" class="btn btn-success btn-block"\
    </div>\
</form>',
    show_login_form: function( container ) {
        $(container).html(
            Mustache.render( my_html._show_login_form_tmpl, {
                I18n: I18n,
            })
        );
    },
    login_form_onsubmit: function() {
        var login = $('#my-auth-login').val();
        var password = $('#my-auth-password').val();
        my.authentify( login, password );
        return false;
    },

    _show_logout_form_tmpl:
'<form method="POST" action="#" role="form" onsubmit="return my_html.logout_form_onsubmit(event)">\
    <div class="form-group">\
        <input type="submit" value="{{I18n.auth_form.sign_out}}" class="btn btn-success btn-block"\
    </div>\
</form>',
    show_logout_form: function( container ) {
        $(container).html(
            Mustache.render( my_html._show_logout_form_tmpl, {
                I18n: I18n,
            })
        );
    },
    logout_form_onsubmit: function() {
        my.sign_out();
        return false;
    },

    new_page: function( title ) {
        var body = my.get_items_container();
        body.html('');
        document.title = title;
        body.append(
            $('<ol/>', { "class": "breadcrumb" }).append(
                $('<li/>', { "class": "active my-page-title", text: title, } )
            ),
            $('<span/>', { id: "my-data-keeper" } )
        );
    },

    breadcrumb: function() {
        var items = my.get_breadcrump();
        items.pop();
        $('.breadcrumb').prepend(
            $.map( items, function(item,i) {
                return $('<li/>').append(
                    $('<a/>', {
                        href: "#" + item.hash,
                        text: item.title,
                    }).click( my.click_handler() )
                );
            })
        );
    },

    get_new_panel: function( title, body ) {
        return $('<div/>', {
            "class": 'col-sm-6',
        }).append(
            $('<div/>', {
                "class": 'panel panel-default',
            }).append(
                $('<div/>', {
                    "class": 'panel-heading',
                }).append(
                    $('<h3>', {
                        "class": 'panel-title',
                        html: title,
                    })
                ),
                $('<div/>', {
                    "class": 'panel-body',
                    html: body,
                })
            )
        );
    },

    _get_edit_album_form_tmpl:
'<form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return my_html.edit_album_form_onsubmit(event)">\
    <div class="form-group">\
        <label class="col-sm-3 control-label" for="my-admin-album-title">{{I18n.admin.title}}</label>\
        <div class="col-sm-9">\
            <input class="form-control" type="text" id="my-admin-album-title" value="{{title}}" />\
        </div>\
    </div>\
    <div class="form-group">\
        <label class="col-sm-3 control-label" for="my-admin-album-thumb">{{I18n.admin.thumb}}</label>\
        <div class="col-sm-9">\
            <select class="form-control" id="my-admin-album-thumb">\
                <option value=""></option>\
                {{#thumbs_list}}\
                <option value="{{value}}"{{#selected}} selected="selected"{{/selected}}>{{label}}</option>\
                {{/thumbs_list}}\
            </select>\
        </div>\
    </div>\
    <div class="form-group">\
        <label class="col-sm-3 control-label" for="my-admin-album-password">{{I18n.admin.password}}</label>\
        <div class="col-sm-9">\
            <div class="input-group">\
                <span class="input-group-addon">\
                    <input type="checkbox" id="my-admin-album-change-password" title="{{I18n.admin.change_password}}"\
                        onclick="my_html.edit_album_form_change_password_onclick(event)" />\
                </span>\
                <input class="form-control" type="password" id="my-admin-album-password"\
                    value="{{#is_protected}}protected{{/is_protected}}" disabled="disabled" />\
            </div>\
        </div>\
    </div>\
    <div class="form-group">\
        <div class="col-sm-offset-3 col-sm-5">\
            <div class="checkbox">\
                <label>\
                    <input type="checkbox" id="my-admin-album-hidden" {{#is_hidden}} checked="checked"{{/is_hidden}} />\
                    {{I18n.admin.album_is_hidden}}\
                </label>\
            </div>\
        </div>\
        <div class="col-sm-4">\
            <input type="submit" value="{{I18n.admin.save}}" class="btn btn-success btn-block" />\
</form>',
    get_edit_album_form: function() {
        var thumb = $('#my-data-keeper').attr('data-thumb');
        var is_protected = $('#my-data-keeper').attr('data-protected');
        var is_hidden = $('#my-data-keeper').attr('data-hidden');
        return Mustache.render( my_html._get_edit_album_form_tmpl, {
            I18n: I18n,
            title: $('.breadcrumb > li.active').text(),
            thumbs_list: $.map( $('.my-item:not(.my-item-stub)'), function ( val, i ) {
                var value = $(val).attr('data-name');
                var props = {
                    label: $( $(val).children('.my-title')[0] ).text(),
                    value: value,
                };
                var rx = new RegExp( '^' + RegExp.escape(value) + '(:|$)' );
                if ( rx.test(thumb) ) {
                    props.selected = 1;
                }
                return props;
            }),
            is_protected: ( is_protected && is_protected == 'true' ),
            is_hidden: ( is_hidden && is_hidden == 'true' ),
        });
    },
    edit_album_form_change_password_onclick: function(e) {
        if ($(e.target).is(':checked')) {
            $('#my-admin-album-password').removeAttr( 'disabled' );
        } else {
            $('#my-admin-album-password').attr( 'disabled', 'disabled' );
        }
    },
    edit_album_form_onsubmit: function() {
        var params = {
            title: $('#my-admin-album-title').val(),
        };
        params.hidden = $('#my-admin-album-hidden').is(':checked') ? 1 : 0;
        if ( $('#my-admin-album-change-password').is(':checked') ) {
            params.password = $('#my-admin-album-password').val();
        }
        if ( my_html.is_folder() ) {
            params.thumb_from = $('#my-admin-album-thumb').val();
        }
        else {
            params.thumb = $('#my-admin-album-thumb').val();
        }
        my_admin.edit_item(params);
        return false;
    },

    _create_tag_modal_tmpl:
'<div class="modal fade" id="create_tag_modal" tabindex="-1" role="dialog"\
    aria-labelledby="create_tag_modal_label" aria-hidden="true">\
    <div class="modal-dialog">\
        <div class="modal-content">\
            <div class="modal-header">\
                <button type="button" class="close" data-dismiss="modal"><span\
                    aria-hidden="true">&times;</span><span class="sr-only">{{I18n.admin.close}}</span></button>\
                <h4 class="modal-title" id="create_tag_modal_label">{{I18n.admin.create_tag}}</h4>\
            </div>\
            <div class="modal-body">\
                <form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return false">\
                    <div class="form-group">\
                        <div class="col-sm-12">\
                            <input class="form-control" type="text" id="my-admin-new-tag" value="" />\
                        </div>\
                    </div>\
                </form>\
            </div>\
            <div class="modal-footer">\
                <button type="button" class="btn btn-default" data-dismiss="modal">{{I18n.admin.close}}</button>\
                <button type="button" class="btn btn-success"\
                    onclick="return my_html.create_tag_modal_onclick(event)">{{I18n.admin.create}}</button>\
            </div>\
        </div>\
    </div>\
</div>',
    _create_tag_modal: function() {
        return Mustache.render( my_html._create_tag_modal_tmpl, {
            I18n: I18n,
        });
    },
    create_tag_modal_onclick: function() {
        $(".has-error").removeClass('has-error');
        var valid = true;

        var tag = $("#my-admin-new-tag").val();
        if ( tag == undefined || tag.length == 0 ) {
            $("#my-admin-new-tag").parent().addClass('has-error');
            valid = false;
        }

        if (valid) {
            my_admin.create_tag({
                tag: tag,
            }, function() {
                my_html.show_ok_message(I18n.info.created_successefully);
                my_html.load_tags_list();
            });
            $('#create_tag_modal').modal('hide');
        }
        return valid;
    },

    _get_edit_images_form_tmpl:
'<form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return false">\
    <div class="form-group">\
        <div class="col-sm-4">\
            <input type="submit" value="{{I18n.admin.select_all}}" class="btn btn-default btn-block"\
                onclick="return my_html.edit_images_form_select_all_onclick(event)" />\
        </div>\
        <div class="col-sm-4">\
            <input type="submit" value="{{I18n.admin.select_none}}" class="btn btn-default btn-block"\
                onclick="return my_html.edit_images_form_select_none_onclick(event)" />\
        </div>\
        <div class="col-sm-4">\
            <input type="submit" value="{{I18n.admin.delete}}" class="btn btn-danger btn-block"\
                onclick="return my_html.edit_images_form_delete_onclick(event)" />\
        </div>\
    </div>\
    <div class="form-group">\
        <div class="col-sm-8">\
            <input class="form-control" type="text" id="my-admin-image-title" placeholder="{{I18n.admin.title}}" />\
        </div>\
        <div class="col-sm-4">\
            <input type="submit" value="{{I18n.admin.change}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_images_form_change_title_onclick(event)" />\
        </div>\
    </div>\
    <div class="form-group">\
        <div class="col-sm-6">\
            <select class="form-control" id="my-admin-image-album">\
                {{{stub_album_item}}}\
            </select>\
        </div>\
        <div class="col-sm-2">\
            <button title="{{I18n.admin.new_album}}" class="btn btn-default btn-block"\
                data-toggle="modal" data-target="#create_album_modal">+</button>\
        </div>\
        <div class="col-sm-4">\
            <input type: "submit" value="{{I18n.admin.move}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_images_form_move_onclick(event)" />\
        </div>\
    </div>\
    <div class="form-group">\
        <div class="col-sm-6">\
            <select class="form-control" id="my-admin-image-tag">\
                {{{stub_tag_item}}}\
            </select>\
        </div>\
        <div class="col-sm-2">\
            <button title="{{I18n.admin.create_tag}}" class="btn btn-default btn-block"\
                data-toggle="modal" data-target="#create_tag_modal">+</button>\
        </div>\
        <div class="col-sm-4">\
            <input type: "submit" value="{{I18n.admin.assign_tag}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_images_form_assign_tag_onclick(event)" />\
        </div>\
    </div>\
</form>\
<div class="modal fade" id="create_album_modal" tabindex="-1" role="dialog"\
    aria-labelledby="create_album_modal_label" aria-hidden="true">\
    <div class="modal-dialog">\
        <div class="modal-content">\
            <div class="modal-header">\
                <button type="button" class="close" data-dismiss="modal"><span\
                    aria-hidden="true">&times;</span><span class="sr-only">{{I18n.admin.close}}</span></button>\
                <h4 class="modal-title" id="create_album_modal_label">{{I18n.admin.new_album}}</h4>\
            </div>\
            <div class="modal-body">\
                <form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return false">\
                    <div class="form-group">\
                        <label class="col-sm-3 control-label" for="my-admin-new-album-name">{{I18n.admin.name}}</label>\
                        <div class="col-sm-9">\
                            <input class="form-control" type="text" id="my-admin-new-album-name" value="" />\
                        </div>\
                    </div>\
                    <div class="form-group">\
                        <label class="col-sm-3 control-label" for="my-admin-new-album-title">{{I18n.admin.title}}</label>\
                        <div class="col-sm-9">\
                            <input class="form-control" type="text" id="my-admin-new-album-title" value="" />\
                        </div>\
                    </div>\
                    <div class="form-group">\
                        <label class="col-sm-3 control-label" for="my-admin-new-album-parent">{{I18n.admin.parent_album}}</label>\
                        <div class="col-sm-9">\
                            <select class="form-control" id="my-admin-new-album-parent" value="" />\
                        </div>\
                    </div>\
                </form>\
            </div>\
            <div class="modal-footer">\
                <button type="button" class="btn btn-default" data-dismiss="modal">{{I18n.admin.close}}</button>\
                <button type="button" class="btn btn-success"\
                    onclick="return my_html.edit_images_form_create_album_onclick(event)">{{I18n.admin.create}}</button>\
            </div>\
        </div>\
    </div>\
</div>\
{{{create_tag_modal}}}',
    get_edit_images_form: function() {
        var result = Mustache.render( my_html._get_edit_images_form_tmpl, {
            I18n: I18n,
            stub_album_item: this._stub_album_item()[0].outerHTML,
            stub_tag_item: this._stub_tag_item()[0].outerHTML,
            create_tag_modal: this._create_tag_modal,
        });

        setTimeout( this.load_albums_list, 500 );
        setTimeout( this.load_tags_list, 500 );

        return result;
    },
    edit_images_form_select_all_onclick: function() {
        $('.my-item:not(.my-item-stub)').addClass('my-selected');
        my_html.update_selected_count();
        return false;
    },
    edit_images_form_select_none_onclick: function() {
        $('.my-item:not(.my-item-stub).my-selected').removeClass('my-selected');
        my_html.update_selected_count();
        return false;
    },
    edit_images_form_delete_onclick: function() {
        var items = $('.my-selected');
        var data_type = items.attr('data-type');
        var message = items.length + " " + data_type + "\n" + I18n.admin.delete_confirmation;
        if ( items.length > 0 && confirm(message) ) {
            var names = $.map( items, function(v,i){ return $(v).attr('data-name') } );
            my_admin.delete_items( data_type, names );
        }
        return false;
    },
    edit_images_form_change_title_onclick: function() {
        var new_title = $('#my-admin-image-title').val();
        my_admin.set_items_title(
            $.map( $('.my-selected'), function(v,i){ return $(v).attr('data-name') } ),
            new_title,
            $('.my-selected').attr('data-type'),
            function() {
                $('.my-selected .my-title').text(new_title);
            }
        );
        return false;
    },
    edit_images_form_create_album_onclick: function() {
        $(".has-error").removeClass('has-error');
        var valid = true;

        var name = $("#my-admin-new-album-name").val();
        if ( name == undefined || !/^[-a-zA-Z0-9_':]+$/.test(name) ) {
            $("#my-admin-new-album-name").parent().addClass('has-error');
            valid = false;
        }

        var title = $("#my-admin-new-album-title").val();
        if ( title == undefined || title == "" ) {
            $("#my-admin-new-album-title").parent().addClass('has-error');
            valid = false;
        }

        var parent_album = $("#my-admin-new-album-parent").val();
        if ( parent_album != null && parent_album != undefined && parent_album != '' ) {
            name = parent_album + ':' + name;
        }

        if (valid) {
            my_admin.create_album({
                name: name,
                title: title,
            }, function() {
                my_html.show_ok_message(I18n.info.created_successefully);
                my_html.load_albums_list();
            });
            $('#create_album_modal').modal('hide');
        }
        return valid;
    },
    edit_images_form_move_onclick: function() {
        var album = $('#my-admin-image-album').val();
        if ( album == undefined || album == null || album == "" ) {
            alert(I18n.error.empty_album_specified);
            return false;
        }
        var items = $('.my-selected');
        var data_type = items.attr('data-type');
        if ( items.length > 0 ) {
            var names = $.map( items, function(v,i){ return $(v).attr('data-name') } );
            my_admin.move_items( data_type, names, album );
        }
        return false;
    },
    edit_images_form_assign_tag_onclick: function() {
        var tag = $('#my-admin-image-tag').val();
        if ( tag == undefined || tag == null || tag == "" ) {
            alert(I18n.error.empty_tag_specified);
            return false;
        }
        var items = $('.my-selected');
        var data_type = items.attr('data-type');
        if ( items.length > 0 ) {
            var names = $.map( items, function(v,i){ return $(v).attr('data-name') } );
            my_admin.assign_tag( data_type, names, tag, function() {
                my_html.show_ok_message(I18n.info.assigned_successefully)
            });
        }
        return false;
    },

    is_folder: function() {
        return  $('#my-data-keeper').attr('data-folder') == 'true';
    },

    update_selected_count: function() {
        $('#my-selected-count').text(
            $('.my-selected').length
        );
    },

    _stub_album_item: function() {
        return $('<option/>', {
            value: '',
            text: I18n.admin.album,
            "class": "my-placeholder",
        });
    },

    _stub_tag_item: function() {
        return $('<option/>', {
            value: '',
            text: I18n.admin.tag,
            "class": "my-placeholder",
        });
    },

    load_albums_list: function() {
        $('#my-admin-image-album').html( my_html._stub_album_item() );
        $('#my-admin-new-album-parent').html( '<option />' );
        my_admin.load_all_albums_list(function( albums_list ) {
            for ( var i in albums_list ) {
                var album = albums_list[i];
                var item = $('<option/>',{
                    value: album.name,
                    text: album.name + " (" + album.title + ")",
                });
                if ( album.folder ) {
                    $('#my-admin-new-album-parent').append(item);
                }
                else {
                    $('#my-admin-image-album').append(item);
                }
            }
        });
    },

    load_tags_list: function() {
        $('#my-admin-image-tag').html( my_html._stub_tag_item() );
        my._get_page_by_hash( 'tag',
            function( data ) {
                var code = data.code;
                if ( code == 200 ) {
                    $('#my-admin-image-tag').append(
                        $.map( data.items, function(tag,i) {
                            return $('<option/>',{
                                value: tag.name,
                                text: tag.name,
                            });
                        })
                    );
                }
                else if ( data.error ) {
                    my_html.show_error_message( data.error );
                }
                else {
                    my_html.show_error_message( I18n.error.internal_error, data );
                }
            },
            function( jqXHR, textStatus, errorThrown ) {
                my_html.show_error_message( I18n.error.internal_error, textStatus );
            }
        );
    },

    _get_edit_image_form_tmpl:
'<form method="POST" action="#" class="form-horizontal" role="form" onsubmit="return false">\
    <div class="form-group">\
        <label class="col-sm-2 control-label" for="my-admin-image-title">{{I18n.admin.title}}</label>\
        <div class="col-sm-7">\
            <input class="form-control" type="text" id="my-admin-image-title" value="{{title}}" />\
        </div>\
        <div class="col-sm-3">\
            <input type="submit" value="{{I18n.admin.change}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_image_form_set_title_click(event)" />\
        </div>\
    </div>\
    <div class="form-group">\
        <div class="col-sm-offset-2 col-sm-5">\
            <select class="form-control" id="my-admin-image-tag">\
                {{{stub_tag_item}}}\
            </select>\
        </div>\
        <div class="col-sm-2">\
            <button title="{{I18n.admin.create_tag}}" class="btn btn-default btn-block"\
                data-toggle="modal" data-target="#create_tag_modal">+</button>\
        </div>\
        <div class="col-sm-3">\
            <input type: "submit" value="{{I18n.admin.assign_tag}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_image_form_assign_tag_onclick(event)" />\
        </div>\
    </div>\
    <div class="form-group">\
        <label class="col-sm-offset-2 col-sm-5 control-label">{{upload_date}}</label>\
        <div class="col-sm-5">\
            <input type: "submit" value="{{I18n.admin.image_of_day}}" class="btn btn-success btn-block"\
                onclick="return my_html.edit_image_form_image_of_day_onclick(event)" />\
        </div>\
    </div>\
</form>\
{{{create_tag_modal}}}',
    get_edit_image_form: function() {
        var result = Mustache.render( my_html._get_edit_image_form_tmpl, {
            I18n: I18n,
            title: $('.breadcrumb > li.active').text(),
            stub_tag_item: this._stub_tag_item()[0].outerHTML,
            create_tag_modal: this._create_tag_modal,
            upload_date: $('#my-data-keeper').attr('data-date-added'),
        });

        setTimeout( this.load_tags_list, 500 );

        return result;
    },
    edit_image_form_set_title_click: function() {
        var params = {
            title: $('#my-admin-image-title').val(),
        };
        my_admin.edit_item(params);
        return false;
    },
    edit_image_form_assign_tag_onclick: function() {
        var tag = $('#my-admin-image-tag').val();
        if ( tag == undefined || tag == null || tag == "" ) {
            alert(I18n.error.empty_tag_specified);
            return false;
        }
        var hash = get_hash_location();
        var name = hash.split('/').pop();
        my_admin.assign_tag( 'image', [name], tag );
        return false;
    },
    edit_image_form_image_of_day_onclick: function() {
        my_admin.set_as_image_of_a_day(function() {
            my_html.show_ok_message(I18n.notice.done);
        });
        return false;
    },
}


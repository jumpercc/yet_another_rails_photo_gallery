function get_absolute_location() {
    var current_page = window.location.href;
    return current_page.substring( 0, current_page.indexOf('#') );
}

function extract_hash(url) {
    var match = /(?:^[^\/]+:\/\/[^\/]+\/#)?(.*?)(?:\.json)?$/.exec(url);
    return match ? match[1] : null;
}

function get_page_title( hash ) {
    if ( hash == null ) {
        return '';
    }

    var hash_parts = hash.split('/');
    if ( hash_parts[0] == 'album' ) {
        if ( hash_parts[1] == undefined ) {
            return I18n.albums_title;
        }
        else {
            return hash_parts[1]; // stub
        }
    }
    else if ( hash_parts[0] == 'date' ) {
        if ( hash_parts[1] == undefined ) {
            return I18n.by_date_title;
        }
        else {
            return hash_parts[1];
        }
    }
    else if ( hash_parts[0] == 'tag' ) {
        if ( hash_parts[1] == undefined ) {
            return I18n.tags_title;
        }
        else {
            return  hash_parts[1];
        }
    }
    else {
        my_html.show_error_message( I18n.error.incorrect_url );
    }
}

function get_hash_location() {
    var new_page = window.location.hash.substring(1);
    if ( !new_page ) {
        new_page = 'album';
    }
    return decodeURIComponent(new_page);
}

RegExp.escape = function(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
};

function get_parent_page( hash ) {
    var match = /^(.+)[\/:][^\/:]+$/.exec(hash);
    var result = match ? match[1] : '';
    result = result.replace( /^image\//, 'album/' );
    return result;
}

function escape_id( id ) {
    return id.replace( /[.# \[\]:]/g, '_' );
}

function get_escaped_id(item) {
    return escape_id( item.day || item.name );
}

function force_https() {
    var current_page = window.location.href;
    if ( ! /^https:/.test(current_page) ) {
        document.location.href = current_page.replace( /^http:/, 'https:' );
    }
}


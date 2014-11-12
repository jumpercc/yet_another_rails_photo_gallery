module ApplicationHelper
  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end

  def signed_in?
    !cookies.signed[:user].nil?
  end

  def breadcrumb_items( current_item = get_current_item )
    items_list = []

    if controller_name == "album" && action_name == "view"
      unless current_item[:main].nil?
        items_list = breadcrumb_for_album current_item[:main].parent
      end
      items_list << { title: current_item[:main].nil? ? t('albums_title') : current_item[:main].title }
    elsif !params[:from].nil?
      if params[:from] == "album"
        items_list = breadcrumb_for_album current_item[:items].first.album
      elsif params[:from] == "tag"
        items_list << { uri: tags_cloud_path, title: t('tags_title') }
        items_list << { uri: a_tag_path(current_item[:main].tag), title: current_item[:main].tag }
      elsif params[:from] == "date"
        items_list << { uri: dates_list_path, title: t('by_date_title') }
        items_list << { uri: a_date_path(current_item[:main]), title: current_item[:main] }
      end
      items_list << { title: current_item[:items].first.title }
    elsif controller_name == "tag"
      items_list << { title: t('tags_title') }
    elsif action_name == "by_tag"
      items_list << { uri: tags_cloud_path, title: t('tags_title') }
      items_list << { title: current_item[:main].tag }
    elsif action_name == "by_date"
      items_list << { uri: dates_list_path, title: t('by_date_title') }
      items_list << { title: current_item[:main] }
    elsif action_name == "calendar"
      items_list << { title: t('by_date_title') }
    end

    items_list
  end

  def get_current_item
    { main: @album || @tag || @date, items: @items }
  end

  def get_nearest( current_item = get_current_item )
    nearest = {}

    if current_item[:main].nil?
      unless controller_name == "album" && action_name == "view"
        nearest[:up] = albums_list_path
      end
    else
      if controller_name == "album"
        if current_item[:main].parent.nil?
          nearest[:up] = albums_list_path
        else
          nearest[:up] = an_album_path current_item[:main].parent.name
        end
      elsif action_name == "by_tag"
        nearest[:up] = tags_cloud_path
      elsif action_name == "by_date"
        nearest[:up] = dates_list_path
      elsif !params[:from].nil?
        if params[:from] == "album"
          nearest[:up] = an_album_path current_item[:items].first.album.name
        elsif params[:from] == "tag"
          nearest[:up] = a_tag_path current_item[:main].tag
        elsif params[:from] == "date"
          nearest[:up] = a_date_path current_item[:main]
        end
        page = current_item[:items].offset + 1
        if page > 1
          nearest[:prev] = url_for page: page - 1
        end
        if page < current_item[:items].total_pages
          nearest[:next] = url_for page: page + 1
        end
      end
    end

    nearest
  end

  def album_thumb(album)
    if album.protected?
        "/protected.png"
    elsif !album.real_thumb.nil?
        "/albums/thumbs/" + album.real_thumb
    else
        "/image_stub.png"
    end
  end

  def image_of_day_thumb(image_of_day)
    "/albums/thumbs/" + image_of_day.image.album.name +
      '/' + image_of_day.image.name
  end

  def album_selected?
    from_item == "album"
  end

  def tag_selected?
    from_item == "tag"
  end

  def date_selected?
    from_item == "date"
  end

  def from_item
    if params[:from].nil?
      if action_name == "by_tag"
        "tag"
      elsif action_name == "by_date" || action_name == "calendar"
        "date"
      elsif controller_name == "tag"
        "tag"
      else
        "album"
      end
    else
      params[:from]
    end
  end

  TAG_BOUNDARIES = [ 8, 16, 32, 64, 128, 256, 512, 1024 ];
  def get_tag_css_class( images_count )
    bound = TAG_BOUNDARIES.find{ |bound| images_count < bound } || TAG_BOUNDARIES[-1]
    "my-tag-#{bound}"
  end

  private

  def breadcrumb_for_album(album)
    albums_list = []
    while !album.nil?
      albums_list << album
      album = album.parent
    end
    items_list = [
        { uri: albums_list_path, title: t('albums_title') }
    ]
    albums_list.reverse.each do |album|
      items_list << { uri: an_album_path(album.name), title: album.title }
    end
    return items_list
  end
end

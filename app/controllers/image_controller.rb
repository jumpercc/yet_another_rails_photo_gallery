class ImageController < ApplicationController
  before_filter :album_authorize, :only => [
    :view, :view_in_list
  ]
  skip_before_filter :authorize_admin, :only => [
    :by_tag, :by_date, :view, :view_in_list
  ]

  def by_date
    unless /\A\d{4}-\d\d-\d\d\Z/.match params[:date]
      return respond_error( 400 )
    end

    @date = params[:date]
    @items = Image.all_by_date( params[:date],
      !params[:nojs] || @lists_order == 'asc' )
    respond_to do |format|
      format.html { nojs_paginate_n_render }
      format.json {
        render :json => {
          code: 200,
          self: { name: params[:date], title: params[:date], },
          items: @items,
        }
      }
    end
  end

  def by_tag
    if params[:tag].nil? || params[:tag].empty?
      return respond_error( 400, I18n.t( 'error.no_tag_specified' ) )
    end

    @tag = Tag.find_by_tag params[:tag]
    if @tag.nil?
      return respond_error( 404 )
    end

    @items = Image.all_by_tag(@tag)
    respond_to do |format|
      format.html { nojs_paginate_n_render 'images' }
      format.json {
        render :json => {
          code: 200,
          self: { name: params[:tag], title: params[:tag], },
          items: @items,
        }
      }
    end
  end

  def view
    if params[:name].nil?
      render :json => { code: 400, error: I18n.t( 'error.no_parameters' ) }
    else
      image = Image.where( name: params[:name] ).first
      if image.nil?
        render :json => { code: 404, error: I18n.t('error.no_image') }
      else
        render :json => { code: 200, self: image, tags: image.tags }
      end
    end
  end

  def update
    if params[:name].nil? || params[:modified].nil?
      render :json => { code: 400, error: I18n.t( 'error.no_parameters' ) }
    else
      image = Image.find_by_name params[:name]
      if image.nil?
        render :json => { code: 404, error: I18n.t('error.no_image') }
      elsif image.update_attributes(image_params)
        render :json => { code: 200, }
      else
        render :json => { code: 500, error: I18n.t('error.image_update_failed') }
      end
    end
  end

  def update_list
    items_list = params[:items_list].nil? ? [] : params[:items_list].split(',')
    if items_list.empty? \
      || params[:modified].nil? || params[:modified].empty?
      render :json => { code: 400,
        error: I18n.t( 'error.no_parameters' ) }
    elsif params[:modified].has_key? "album"
      album = Album.find_by_name params[:modified]["album"]
      if album.nil?
        render :json => { code: 404 }
      else
        Image.where( name: items_list ).each do |image|
          image.change_album album
        end
        render :json => { code: 200 }
      end
    elsif params[:modified].has_key? "tag"
      tag = Tag.find_by_tag params[:modified]["tag"]
      if tag.nil?
        render :json => { code: 404 }
      else
        tagged_images = {}
        tag.images.each do |image|
          tagged_images[image.id] = 1
        end

        Image.where( name: items_list ).each do |image|
          if !tagged_images.has_key? image.id
            tag.images << image
          end
        end
        tag.save!
        render :json => { code: 200 }
      end
    else
      items_list.each do |name|
        image = Image.find_by_name name
        if image.nil?
          render :json => { code: 404 }
          return
        elsif !image.update_attributes(image_params)
          render :json => { code: 500, error: I18n.t('error.image_update_failed') }
          return
        end
      end
      render :json => { code: 200 }
    end
  end

  def remove_tag
    if  params[:tag].nil?
      render :json => { code: 400,
        error: I18n.t( 'error.no_parameters' ) }
    else
      image = Image.find_by_name params[:name]
      if image.nil?
        render :json => { code: 404 }
        return
      end

      image.tags = image.tags.reject do |t|
        t.tag == params[:tag]
      end
      render :json => { code: 200 }
    end
  end

  def delete
    image = Image.find_by_name( params[:name] )
    if image.nil?
      render :json => { code: 404 }
    else
      image.destroy
      render :json => { code: 200 }
    end
  end

  def set_as_image_of_a_day
    image = Image.find_by_name params[:name]
    if image.nil?
      render :json => { code: 404 }
    else
      ImageOfDay.mark_as_image_of_day image.created_at, image
      render :json => { code: 200 }
    end
  end

  def view_in_list
    if !params[:album].nil?
      @album = Album.find_by_name( params[:album] )
      if @album.nil?
        return respond_error(404)
      end
      @items = Image.where( album_id: @album.id )
    elsif !params[:tag].nil?
      @tag = Tag.find_by_tag params[:tag]
      if @tag.nil?
        return respond_error(404)
      end
      @items = Image.all_by_tag(@tag)
    elsif !params[:date].nil?
      @date = params[:date]
      unless /\A\d{4}-\d\d-\d\d\Z/.match @date
        return respond_error(404)
      end
      @items = Image.all_by_date( @date,
        !params[:nojs] || @lists_order == 'asc' )
    else
      return respond_error(400)
    end

    nojs_paginate_n_render 'images', 1
  end

  private

  def image_params
    params.require(:modified).permit(
      :title
    )
  end
end

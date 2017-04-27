class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :determine_locale, :determine_image_size, :determine_lists_order, :authorize_admin, :html_gui

  attr_reader :image_size

  def image_size
    if @image_size.nil?
      determine_image_size
    end

    @image_size
  end

  protected

  def respond_error( code, error=nil )
    respond_to do |format|
      format.html { render status: code }
      format.json {
        json_body = { code: code }
        unless error.nil?
          json_body[:error] = error;
        end
        render :json => json_body
      }
    end
    return
  end

  def nojs_paginate_n_render( with_sort = false, items_per_page = images_per_page )
    if with_sort
      order = (@lists_order == 'desc') ? ' DESC' : ''
      sort_fields = [ 'created_at', 'name' ]
      if with_sort.length > 0
        with_sort = with_sort + '.'
      end
      order_str = sort_fields.collect{ |f| with_sort + f + order }.join(', ')
      @items = @items.order order_str
    end
    @items = @items
      .page(params[:page])
      .per_page( items_per_page )
    render layout: "nojs"
  end

  IMAGE_SIZES = Image.styles.sort { |a,b|
    a.split(/x/)[0].to_i <=> b.split(/x/)[0].to_i
  }.reject { |s|
    s == 'thumbs'
  }
  DEFAULT_IMAGE_SIZE = '1200x800'

  def determine_image_size
    if request.session[:image_size].nil?
      @image_size = DEFAULT_IMAGE_SIZE
    else
      @image_size = request.session[:image_size]
    end

    @all_image_sizes = IMAGE_SIZES
  end

  def authorize_admin
    if !User.autorized? cookies
      render :json => { code: 403, error: 'login required' }
    end
  end

  MAX_TAGS_IN_SEARCH = 3

  def max_tags_in_search
    MAX_TAGS_IN_SEARCH
  end

  def album_authorize
    album = get_album params
    unless album.nil?
      protected_album = AlbumProtection.authorize album, cookies
      unless protected_album.nil?
        render :json => { code: 403, self: album, :password_for => protected_album.name, }
        return false
      end
    end
    true
  end

  def get_album( params )
    if params[:album].nil?
      nil
    else
      album = Album.find_by_name( params[:album] )
      if album.nil?
        nil
      else
        album
      end
    end
  end

  def determine_lists_order
    if request.session[:lists_order].nil?
      @lists_order = 'asc'
    else
      @lists_order = request.session[:lists_order]
    end
    @all_lists_orders = [ 'asc', 'desc' ]
  end

  def nojs?
    return params[:nojs].nil? ? false : true
  end

  def images_per_page
    15
  end

  private

  def html_gui
    unless params[:nojs] || params[:format] && params[:format] == "json"
      if request.fullpath == '/'
        render :action => "gui"
      else
        uri = request.fullpath
        uri.sub! /^\//, ''
        redirect_to "#" + uri
      end
    end
  end

  def determine_locale
    if !request.session[:locale].nil?
      I18n.locale = request.session[:locale]
    end
  end
end

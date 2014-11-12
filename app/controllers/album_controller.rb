require 'album_protection'

class AlbumController < ApplicationController
  before_filter :album_authorize, :only => :view
  skip_before_filter :authorize_admin, :only => [
    :view, :calendar, :by_tag, :authentify
  ]

  def view
    need_unprotect = false
    if params[:album].nil?
      @album = nil
      collection = Album.get_toplevel_albums_list
    else
      album = Album.find_by_name( params[:album] )
      if album.nil?
        return respond_error( 404 )
      elsif album.folder?
        @album = album
        collection = album.subalbums.public_only
        need_unprotect = true
      else
        @album = album
        collection = album.images
      end
    end

    if collection.nil?
      @items = []
    elsif params[:nojs] && !@album.nil?
      @items = collection
    else
      @items = collection.order('created_at, name')
    end

    if !params[:nojs] && need_unprotect
      @items.collect! do |a|
        if a.protected && AlbumProtection.authorize( a, cookies ).nil?
          a.as_json({ no_protection: true })
        else
          a
        end
      end
    end

    json_abum = @album
    if !@album.nil? \
    && @album.protected \
    && AlbumProtection.authorize( @album, cookies ).nil?
      json_abum = @album.as_json({ no_protection: true })
    end
    respond_to do |format|
      format.html { nojs_paginate_n_render '' }
      format.json { render :json => { code: 200, items: @items, self: json_abum } }
    end
  end

  def hidden_albums
    album = {
      name: 'hidden',
      title: I18n.t('navigation.hidden_albums'),
    }
    items = Album.all.hidden_only.order('created_at, name')
    render :json => { code: 200, items: items, self: album }
  end

  def calendar
    @items = ImageOfDay.list( @lists_order == 'asc' )
    respond_to do |format|
      format.html { nojs_paginate_n_render }
      format.json {
        render :json => { code: 200, items: @items }
      }
    end
  end

  def authentify
    album = get_album params
    if album.nil?
      render :json => { code: 404 }
    else
      if AlbumProtection.authentify album, params[:password], cookies
        render :json => { code: 200 }
      else
        render :json => { code: 403, self: album, }
      end
    end
  end

  def update
    album = Album.find_by_name( params[:album] )
    if album.nil?
      render :json => { code: 404 }
    else
      if album.update_attributes(album_params)
        render :json => { code: 200 }
      else
        render :json => { code: 500, error: I18n.t('error.album_update_failed') }
      end
    end
  end

  def list_all
    render :json => { code: 200, items:
      Album.all.order(:name).collect do |album|
        album.as_json({ no_protection: true })
      end
    }
  end

  def create
    if !/\A[-a-zA-Z0-9_']+(?::[-a-zA-Z0-9_']+)*\Z/.match params[:new][:name]
      render :json => { code: 400,
        error: I18n.t('error.invalid_album_name') }
      return
    end

    album = Album.find_by_name( params[:new][:name] )
    if !album.nil?
      render :json => { code: 400,
        error: I18n.t('error.album_already_exists') }
      return
    end

    parts = params[:new][:name].split ':'
    parent_album = nil
    parts.each_index do |i|
      album_name = parts.slice( 0..i ).join ':'
      current_album = Album.find_by_name album_name
      if current_album.nil?
        current_abum = Album.create! \
          :name      => album_name,
          :title     => ( album_name == params[:new][:name] ) \
            ? params[:new][:title]
            : album_name,
          :folder    => ( album_name != params[:new][:name] ),
          :parent_id => parent_album.nil? \
            ? nil
            : parent_album.id
      end
      parent_album = current_album
    end

    render :json => { code: 200, }
  end

  def delete
    album = Album.find_by_name( params[:album] )
    if album.nil?
      render :json => { code: 404 }
    else
      album.destroy
      render :json => { code: 200 }
    end
  end

  private

  def album_params
    params.require(:modified).permit(
      :title, :thumb, :password, :thumb_from, :hidden
    )
  end
end

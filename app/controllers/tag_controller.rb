class TagController < ApplicationController
  skip_before_filter :authorize_admin, :only => [
    :list_tags
  ]

  def list_tags
    @items = Tag.all_with_images_count
    respond_to do |format|
      format.html { render layout: "nojs" }
      format.json { render :json => { code: 200, items: @items } }
    end
  end

  def create
    tag = Tag.find_by_tag( params[:new][:tag] )
    if !tag.nil?
      render :json => { code: 400,
        error: I18n.t('error.tag_already_exists') }
      return
    end

    Tag.create! tag: params[:new][:tag]

    render :json => { code: 200 }
  end

  def delete
    tag = Tag.find_by_tag( params[:tag] )
    if tag.nil?
      render :json => { code: 404 }
    else
      tag.destroy
      render :json => { code: 200 }
    end
  end
end

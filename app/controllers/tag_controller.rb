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
end

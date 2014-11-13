CJGallery::Application.routes.draw do
  get  "album" => "album#view"
  get  "album/list_all" => "album#list_all"
  post "album/create" => "album#create"
  get  "album/hidden" => "album#hidden_albums"
  get  "album/:album" => "album#view", :as => :an_ajax_album
  post "album/:album/auth" => "album#authentify"
  post "album/:album/update" => "album#update"
  post "album/:album/delete" => "album#delete"

  get "date"         => "album#calendar"
  get "date/:date"   => "image#by_date"

  get "tag"              => "tag#list_tags"
  get "tag/:tag"         => "image#by_tag"
  post "tag/create"      => "tag#create"
  post "tag/:tag/delete" => "tag#delete"

  get  "image/:album/:name(.:format)" => "image#view", :name => /[-_A-Za-z0-9\.]+?/
  get  "album/:album/:name(.:format)" => "image#view", :name => /[-_A-Za-z0-9\.]+?/
  get  "date/:date/:name(.:format)"   => "image#view", :name => /[-_A-Za-z0-9\.]+?/
  get  "tag/:tag/:name(.:format)"     => "image#view", :name => /[-_A-Za-z0-9\.]+?/
  post "image/:album/:name/update" => "image#update", :name => /[-_A-Za-z0-9\.]+?/
  post "image/:name/delete" => "image#delete", :name => /[-_A-Za-z0-9\.]+?/
  post "image/update_list" => "image#update_list"
  post "image/:album/:name/remove_tag" => "image#remove_tag", :name => /[-_A-Za-z0-9\.]+?/

  post "album/:album/:name/image_of_a_day" => "image#set_as_image_of_a_day", :name => /[-_A-Za-z0-9\.]+?/
  post "tag/:tag/:name/image_of_a_day" => "image#set_as_image_of_a_day", :name => /[-_A-Za-z0-9\.]+?/
  post "date/:date/:name/image_of_a_day" => "image#set_as_image_of_a_day", :name => /[-_A-Za-z0-9\.]+?/

  post "login" => "session#login"
  post "logout" => "session#logout"

  get "settings/locale/:locale" => "session#set_locale",
    :as => :set_locale
  get "settings/image_size/:image_size" => "session#set_image_size",
    :as => :set_image_size
  get "settings/lists_order/:lists_order" => "session#set_lists_order",
    :as => :set_lists_order

  scope :nojs, nojs: true do
    get "album"        => "album#view", :as => :albums_list
    get "album/:album" => "album#view", :as => :an_album

    get "date"         => "album#calendar", :as => :dates_list
    get "date/:date"   => "image#by_date", :as => :a_date

    get "tag"          => "tag#list_tags", :as => :tags_cloud
    get "tag/:tag"     => "image#by_tag", :as => :a_tag

    get "album/:album/image" => "image#view_in_list",
      :as => :album_image, :from => "album"
    get "date/:date/image"   => "image#view_in_list",
      :as => :date_image,  :from => "date"
    get "tag/:tag/image"     => "image#view_in_list",
      :as => :tag_image,   :from => "tag"
  end

  root :to => "album#view"
end

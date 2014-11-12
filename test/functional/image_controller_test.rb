# encoding: UTF-8
require 'test_helper'

class ImageControllerTest < ActionController::TestCase
  test "images, by_tag json" do
    get :by_tag, :tag => tags(:one).tag, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
    assert json_response.has_key?('self'), 'has self'
  end

  test "images, by_tag html" do
    get :by_tag, :tag => tags(:one).tag
    assert_redirected_to "#tag/#{tags(:one).tag}"
  end

  test "images, by_date json" do
    get :by_date, :date => images(:one).created_at, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
    assert json_response.has_key?('self'), 'has self'
  end

  test "images, by_date html" do
    get :by_date, :date => images(:one).created_at
    assert_redirected_to "#date/#{images(:one).created_at}"
  end

  test "view image, json" do
    get :view, :album => images(:one).album.name, :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'

    expected_self = {}
    images(:one).as_json.each_pair do |k,v|
      expected_self[ k.to_s ] = ( k == :image_of_day ) \
        ? v
        : v.nil? \
          ? nil
          : v.to_s
    end
    assert_equal json_response['self'], expected_self, 'has self'

    expected_tags = []
    images(:one).tags.each do |tag|
      tag_json = {}
      tag.as_json.each_pair do |k,v|
        tag_json[ k.to_s ] = v.nil? ? nil : v.to_s
      end
      expected_tags << tag_json
    end
    assert_equal json_response['tags'], expected_tags, 'has tags'
  end

  test "view image, html" do
    get :view, :album => images(:one).album.name, :name => images(:one).name
    assert_redirected_to "#image/#{images(:one).album.name}/#{images(:one).name}"
  end

  test "update list" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :update_list,
      :items_list => albums(:devons).images.collect{|i| i.name}.join(','),
      :modified => { :title => 'test' }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']

    albums(:devons).images.each do |i|
      get :view, :album => albums(:devons).name,
        :name => i.name, :format => "json"
      assert_response :success
      assert_equal 200, json_response['code']
      assert_equal 'test', json_response['self']['title']
    end
  end

  test "view image, protected" do
    get :view, :album => albums(:myr).name,
      :name => albums(:myr).images[0].name, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code']
    assert_equal albums(:protected).name,
      json_response['password_for']
  end

  test "update list, move" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    images_list = albums(:devons).images
    post :update_list,
      :items_list => images_list.collect{|i| i.name}.join(','),
      :modified => { :album => albums(:protected2).name }, :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    images_list.each do |i|
      get :view, :album => albums(:protected2).name,
        :name => i.name, :format => "json"
      assert_response :success
      assert_equal 200, json_response['code']
    end
  end

  test "delete" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :delete, :name => images(:one).name , :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    post :delete, :name => images(:one).name , :format => "json"
    assert_response :success
    assert_equal 404, json_response['code']
  end

  test "update list, assign a tag" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    images_list = albums(:devons).images
    post :update_list,
      :items_list => images_list.collect{|i| i.name}.join(','),
      :modified => { :tag => tags(:unassigned).tag }, :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    images_list.each do |i|
      get :view, :album => albums(:devons).name,
        :name => i.name, :format => "json"
      assert_response :success
      assert_equal 200, json_response['code']
      assert_not_empty json_response['tags'].select{|tag|\
        tag['name'] == tags(:unassigned).tag }
    end
  end

  test "update one" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :update, :album => images(:one).album.name,
      :name => images(:one).name,
      :modified => { :title => "test_one" }, :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    get :view, :album => images(:one).album.name,
      :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_equal 'test_one', json_response['self']['title']
  end

  test "remove tag" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    tag = images(:one).tags[0].tag

    get :view, :album => images(:one).album.name,
      :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_not_empty json_response['tags'].select{|t|\
      t['name'] == tag }

    post :remove_tag, :album => images(:one).album.name,
      :name => images(:one).name,
      :tag => tag, :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    get :view, :album => images(:one).album.name,
      :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_empty json_response['tags'].select{|t|\
      t['name'] == tag }
  end

  test "image of a day" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    tag = images(:one).tags[0].tag

    get :view, :album => images(:one).album.name,
      :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert json_response['self']['image_of_day'], "one is an image of day before"

    get :view, :album => images(:two).album.name,
      :name => images(:two).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_not json_response['self']['image_of_day'], "two is not an image of day before"

    post :set_as_image_of_a_day, :album => images(:two).album.name,
      :name => images(:two).name, :format => "json"
    assert_response :success
    assert_equal nil, json_response['error']
    assert_equal 200, json_response['code']

    get :view, :album => images(:one).album.name,
      :name => images(:one).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_not json_response['self']['image_of_day'], "one is not an image of day after"

    get :view, :album => images(:two).album.name,
      :name => images(:two).name, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert json_response['self']['image_of_day'], "two is an image of day after"
  end

  test "view image nojs" do
    first_image = albums(:devons).images
      .order('images.created_at, images.name').first
    get :view_in_list, :album => albums(:devons).name,
      :nojs => true, :from => "album"
    assert_response :success
    assert_select 'title', first_image.title
    assert_select '.breadcrumb .active', first_image.title
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('albums_title')
    assert_select '.my-nav-text', 1
    assert_select '.my-nav-link', 2
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      an_album_path( albums(:devons).name )
    assert_equal css_select('#my-nav-next-link > a')[0]['href'],
      album_image_path( album: albums(:devons).name, page: 2 )

    assert_equal css_select('.my-big-image')[0]['title'],
      first_image.title
  end

  test "images, by_tag nojs" do
    get :by_tag, :tag => tags(:one).tag, :nojs => true
    assert_response :success
    assert_select 'title', tags(:one).tag
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('tags_title')
    assert_select '.breadcrumb .active', tags(:one).tag
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      tags_cloud_path
    assert_select '.my-nav-text', 0

    assert_equal css_select('.my-item > a')[0]['href'],
      tag_image_path( tag: tags(:one).tag, page: 1 )
  end

  test "view image from tag nojs" do
    get :view_in_list, :tag => tags(:one).tag,
      :nojs => true, :from => "tag"
    assert_response :success
    assert_select 'title', Image.all_by_tag(tags(:one)).first.title
    assert_select '.breadcrumb .active', Image.all_by_tag(tags(:one)).first.title
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('tags_title')
    assert_select '.my-nav-text', 1
    assert_select '.my-nav-link', 2
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      a_tag_path( tags(:one).tag )
    assert_equal css_select('#my-nav-next-link > a')[0]['href'],
      tag_image_path( tag: tags(:one).tag, page: 2 )
    assert_equal css_select('.my-big-image')[0]['title'],
      Image.all_by_tag(tags(:one)).first.title
  end

  test "images, by_date nojs" do
    date = images(:one).created_at.to_s
    get :by_date, :date => date, :nojs => true
    assert_response :success
    assert_select 'title', date
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('by_date_title')
    assert_select '.breadcrumb .active', date
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      dates_list_path
    assert_select '.my-nav-text', 0

    assert_equal css_select('.my-item > a')[0]['href'],
      date_image_path( date: date, page: 1 )
    assert_equal css_select('.my-title')[0].children[0].to_s,
      Image.all_by_date(date).first.title
  end

  test "images, by_date reverse nojs" do
    request.session[:lists_order] = 'desc'
    date = images(:one).created_at.to_s
    get :by_date, :date => date, :nojs => true
    assert_response :success

    assert_equal css_select('.my-title')[0].children[0].to_s,
      Image.all_by_date(date).last.title
  end

  test "view image from date nojs" do
    date = images(:one).created_at.to_s
    get :view_in_list, :date => date,
      :nojs => true, :from => "date"
    assert_response :success
    assert_select 'title', Image.all_by_date(date).first.title
    assert_select '.breadcrumb .active', Image.all_by_date(date).first.title
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('by_date_title')
    assert_select '.my-nav-text', 1
    assert_select '.my-nav-link', 2
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      a_date_path( date )
    assert_equal css_select('#my-nav-next-link > a')[0]['href'],
      date_image_path( date: date, page: 2 )
    assert_equal css_select('.my-big-image')[0]['title'],
      Image.all_by_date(date).first.title
  end

  test "view image from date reverse nojs" do
    request.session[:lists_order] = 'desc'
    date = images(:one).created_at.to_s
    get :view_in_list, :date => date,
      :nojs => true, :from => "date"
    assert_response :success
    assert_select 'title', Image.all_by_date(date).last.title
  end
end

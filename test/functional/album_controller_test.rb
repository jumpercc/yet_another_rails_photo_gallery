require 'test_helper'

class AlbumControllerTest < ActionController::TestCase
  fixtures :all

  test "top level albums json" do
    get :view, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
    assert_nil json_response['self'], 'no self'
    protected_one = json_response['items'].find{ |i| i['name'] == 'protected' }
    assert_not protected_one.has_key?('thumb'), 'no thumb'
  end

  test "top level albums html" do
    get :view
    assert_redirected_to "#album"
  end

  test "list subalbums json" do
    get :view, params: { :album => albums(:cats).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
    assert_equal json_response['self']['title'], albums(:cats).title, 'has self'
  end

  test "list subalbums html" do
    get :view, params: { :album => albums(:cats).name }
    assert_redirected_to "#album/#{albums(:cats).name}"
  end

  test "list images json" do
    get :view, params: { :album => albums(:devons).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
    assert_equal json_response['self']['title'], albums(:devons).title, 'has self'
  end

  test "list images html" do
    get :view, params: { :album => albums(:devons).name }
    assert_redirected_to "#album/#{albums(:devons).name}"
  end

  test "no album json" do
    get :view, params: { :album => '121212' }, :format => "json"
    assert_response :success
    assert_equal 404, json_response['code'], 'code eq 404'
    assert_not json_response.has_key?('items'), 'no items'
    assert_nil json_response['self'], 'no self'
  end

  test "no album html" do
    get :view, params: { :album => '121212' }
    assert_redirected_to "#album/121212"
  end

  test "list by date json" do
    get :calendar, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
  end

  test "list by date html" do
    get :calendar
    assert_redirected_to "#date"
  end

  test "list protected album, json" do
    get :view, params: { :album => albums(:protected).name }, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code'], 'code eq 403'
    assert json_response.has_key?('self'), 'has self'
    if json_response.has_key?('self')
      assert_equal json_response['self']['title'], \
        albums(:protected).title, 'has title'
    end
  end

  test "list protected album, html" do
    get :view, params: { :album => albums(:protected).name }
    assert_redirected_to "#album/" + albums(:protected).name
  end

  test "album auth, wrong" do
    post :authentify, params: { :album => albums(:protected).name, \
      :password => 'wrong' }, :format => "json"
    assert_response :success, 'wrong pass, response'
    assert_equal 403, json_response['code'], 'wrong pass, 403'
  end

  test "album auth" do
    pass = '123'
    albums(:protected).password = pass
    albums(:protected).save!

    post :authentify, params: { :album => albums(:protected).name, \
      :password => pass }, :format => "json"
    assert_response :success, 'pass, response'
    assert_equal 200, json_response['code'], 'pass, 200'
    albums_value = {}
    albums_value[albums(:protected).name] = 1
    assert_equal albums_value, cookies.signed[:albums]

    get :view, params: { :album => albums(:protected).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'authirized now'
    json_response['items'].each do |item|
      assert item.has_key?('thumb'), "#{item['name']} has thumb"
    end
    assert_equal albums(:protected).thumb_album.name + "/" + albums(:protected).thumb_album.thumb,
      json_response['self']['thumb']

    pass = '456'
    albums(:protected2).password = pass
    albums(:protected2).save!

    post :authentify, params: { :album => albums(:protected2).name, \
      :password => pass }, :format => "json"
    assert_response :success, 'pass, response'
    assert_equal 200, json_response['code'], 'pass, 200'
    albums_value[albums(:protected2).name] = 1
    assert_equal albums_value, cookies.signed[:albums]

    get :view, params: { :album => albums(:protected).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'authirized now'

    get :view, params: { :album => albums(:protected2).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'authirized now'
  end

  test "album update" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :update, params: { :album => albums(:protected).name, \
      :modified => { :title => 'test' } }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']

    get :view, params: { :album => albums(:protected).name }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_equal 'test', json_response['self']['title']
  end

  test "list all albums" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    get :list_all, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    expected_albums = [
      'cats',
      'devons',
      'protected',
      'protected2',
      'hidden',
      'myr',
    ].collect do |name|
      album = albums(name.to_sym)
      {
        'name'      => album.name,
        'title'     => album.title,
        'protected' => album.protected,
        'folder'    => album.folder,
        'thumb'     => album.real_thumb,
        'added'     => album.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
        'modified'  => album.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
        'hidden'    => album.hidden,
      }
    end
    assert_equal expected_albums, json_response['items']
  end

  test "album create" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :create, params: { :new => { :name => 'test', :title => 'Test' } },
      :format => "json"
    assert_response :success
    assert_nil json_response['error']
    assert_equal 200, json_response['code']

    get :view, params: { :album => 'test' }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_equal 'Test', json_response['self']['title']
  end

  test "album create subalbum" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :create, params: { :new => { :name => 'protected:test', :title => 'Test' } },
      :format => "json"
    assert_response :success
    assert_nil json_response['error']
    assert_equal 200, json_response['code']

    get :view, params: { :album => 'protected:test' }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_equal 'Test', json_response['self']['title']

    get :view, params: { :album => 'protected' }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_not_empty json_response['items'].select{|a|\
      a['name'] == 'protected:test' }
  end

  test "album delete" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :delete, params: { :album => albums(:protected2).name },
      :format => "json"
    assert_response :success
    assert_nil json_response['error']
    assert_equal 200, json_response['code']

    get :view, params: { :album => albums(:protected2).name },\
      :format => "json"
    assert_response :success
    assert_equal 404, json_response['code']
  end

  test "list subalbums nojs" do
    get :view, params: { :album => albums(:cats).name, :nojs => true }
    assert_response :success
    assert_select 'title', albums(:cats).title
    assert_select '.breadcrumb .active', albums(:cats).title
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('albums_title')
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      albums_list_path
    assert_select '.my-nav-text', 0
    assert_select '.my-item', albums(:cats).subalbums.length

    assert_equal css_select('.my-item > a')[0]['href'],
      an_album_path( albums(:cats).subalbums.first.name )
  end

  test "list images nojs" do
    get :view, params: { :album => albums(:devons).name, :nojs => true }
    assert_response :success
    assert_select 'title', albums(:devons).title
    assert_select '.breadcrumb .active', albums(:devons).title
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('albums_title')
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      an_album_path( albums(:devons).parent.name )
    assert_select '.my-nav-text', 0
    assert_select '.my-item', albums(:devons).images.length

    assert_equal css_select('.my-item > a')[0]['href'],
      album_image_path( album: albums(:devons).name, page: 1 )
  end

  test "list by date nojs" do
    get :calendar, params: { :nojs => true }
    assert_response :success
    assert_select 'title', I18n.t('by_date_title')
    assert_select '.breadcrumb .active', I18n.t('by_date_title')
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('by_date_title')
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      albums_list_path
    assert_select '.my-nav-text', 0
    assert_select '.my-item', ImageOfDay.list.length

    assert_equal css_select('.my-item > a')[0]['href'],
      a_date_path( ImageOfDay.list.first.day )
  end

  test "list by date, reverse nojs" do
    request.session[:lists_order] = 'desc'
    get :calendar, params: { :nojs => true }
    assert_response :success
    assert_equal css_select('.my-item > a')[0]['href'],
      a_date_path( ImageOfDay.list.last.day )
  end

  test "hidden albums, no auth, json" do
    get :hidden_albums, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code']
  end

  test "hidden albums json" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    get :hidden_albums, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert json_response.has_key?('items'), 'has items'
    assert_not_nil json_response['self'], 'has self'
    assert_equal json_response['self']['title'],
      I18n.t('navigation.hidden_albums')
    protected_one = json_response['items']\
      .find{ |i| i['name'] == albums(:hidden).name }
  end
end

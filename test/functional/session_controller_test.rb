require 'test_helper'

class SessionControllerTest < ActionController::TestCase
  fixtures :all

  test "login no parameters" do
    post :login, :format => "json"
    assert_response :success
    assert_equal 409, json_response['code']
    assert_equal I18n.t('error.no_parameters'), json_response['error']
  end

  test "wrong user" do
    post :login, params: { :login => 'asdasdasd', :password => 'wefdynasdfu' }, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code']
    assert_equal I18n.t('error.wrong_password'), json_response['error']
  end

  test "wrong password" do
    post :login, params: { :login => users(:user1).name, :password => 'wefdynasdfu' }, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code']
    assert_equal I18n.t('error.wrong_password'), json_response['error']
  end

  test "login successeful" do
    post :login, params: { :login => users(:user1).name, :password => 'super pass' }, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    assert_equal users(:user1).name, cookies.signed[:user]
  end

  test "logout, no user" do
    post :logout, :format => "json"
    assert_response :success
    assert_equal 403, json_response['code']
  end

  test "logout" do
    cookies.signed[:user] = {
      value: users(:user1).name,
      secure: true,
    }
    post :logout, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code']
    #assert_nil cookies.signed[:user]
  end

  test "set locale, no referer" do
    get :set_locale, params: { :locale => 'en' }
    assert_redirected_to '/'
    assert_nil flash[:alert]
    assert_equal :en, request.session[:locale]
  end

  test "set locale" do
    referer = 'http://some.host/url'
    @request.env['HTTP_REFERER'] = referer
    get :set_locale, params: { :locale => 'en' }
    assert_redirected_to referer
    assert_nil flash[:alert]
    assert_equal :en, request.session[:locale]
  end

  test "set locale, hash" do
    hash = 'tag/test'
    get :set_locale, params: { :locale => 'en', :hash => hash }
    assert_redirected_to '/#' + hash
    assert_nil flash[:alert]
    assert_equal :en, request.session[:locale]
  end

  test "set image_size, hash" do
    hash = 'tag/test'
    get :set_image_size, params: { :image_size => '750x500', :hash => hash }
    assert_redirected_to '/#' + hash
    assert_nil flash[:alert]
    assert_equal '750x500', request.session[:image_size]
  end

  test "set lists_order, hash" do
    hash = 'tag/test'
    get :set_lists_order, params: { :lists_order => 'desc', :hash => hash }
    assert_redirected_to '/#' + hash
    assert_nil flash[:alert]
    assert_equal 'desc', request.session[:lists_order]
  end

  test "set lists_order, hash, encoding needed" do
    hash = 'tag/Тест'
    get :set_lists_order, params: { :lists_order => 'desc', :hash => hash }
    assert_redirected_to '/#tag/%D0%A2%D0%B5%D1%81%D1%82'
    assert_nil flash[:alert]
    assert_equal 'desc', request.session[:lists_order]
  end
end

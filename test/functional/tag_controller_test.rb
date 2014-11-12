require 'test_helper'

class TagControllerTest < ActionController::TestCase
  test "list tags json" do
    get :list_tags, :format => "json"
    assert_response :success
    assert_equal 200, json_response['code'], 'code eq 200'
    assert json_response.has_key?('items'), 'has items'
  end

  test "list tags html" do
    get :list_tags
    assert_redirected_to "#tag"
  end

  test "list tags nojs" do
    get :list_tags, :nojs => true
    assert_response :success
    assert_select 'title', I18n.t('tags_title')
    assert_select 'ul.nav > li.active', 1
    assert_select 'ul.nav > li.active > a', I18n.t('tags_title')
    assert_select '.breadcrumb .active', I18n.t('tags_title')
    assert_select '.my-nav-link', 1
    assert_equal css_select('#my-nav-up-link > a')[0]['href'],
      albums_list_path
    assert_select '.my-nav-text', 0
    assert_select '.my-content > a', Tag.all_with_images_count.size
  end
end

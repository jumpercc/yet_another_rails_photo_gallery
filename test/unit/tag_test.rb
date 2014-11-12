require 'test_helper'

class TagTest < ActiveSupport::TestCase
  fixtures :all

  test "has images" do
    assert_equal 2, tags(:one).images.size
    assert_equal [ images(:one) ], tags(:two).images
  end

  test "all_with_images_count" do
    tags = Tag.all_with_images_count
    assert_equal 2, tags.length

    assert_equal tags(:one).attributes.merge({ "images_count" => 2 }),
      tags.first.attributes

    assert_equal tags(:two).attributes.merge({ "images_count" => 1 }),
      tags.last.attributes
  end

  test "as_json" do
    assert_equal tags(:one).as_json,
      {
        :name => tags(:one).tag,
      }

    assert_equal Tag.all_with_images_count.first.as_json,
      {
        :name         => tags(:one).tag,
        :images_count => 2,
      }
  end
end

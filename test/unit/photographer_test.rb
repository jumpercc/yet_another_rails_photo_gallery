require 'test_helper'

class PhotographerTest < ActiveSupport::TestCase
  test "has_images" do
    assert_equal photographers(:one).images, [ images(:two) ]
    assert_equal photographers(:two).images, []
  end
end

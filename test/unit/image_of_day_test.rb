require 'test_helper'

class ImageOfDayTest < ActiveSupport::TestCase
  test "has image" do
    assert_equal image_of_days(:one).image, images(:one)
  end

  test "mark as image of day" do
    assert_equal image_of_days(:one).image, images(:one)
    ImageOfDay.mark_as_image_of_day images(:one).created_at, images(:two)
    assert_equal image_of_days(:one).reload.image, images(:two)
  end

  test "as_json" do
    assert_equal ImageOfDay.list.last.as_json,
      {
        :day          => images(:one).created_at.to_s,
        :name         => images(:one).name,
        :album        => images(:one).album.name,
      }
  end
end

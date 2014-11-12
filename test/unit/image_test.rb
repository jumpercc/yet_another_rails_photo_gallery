# encoding: UTF-8
require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  fixtures :all

  test "has album" do
    assert_equal images(:one).album.name, albums(:devons).name
  end

  test "has tags" do
    assert_equal 2, images(:one).tags.size
    assert_equal [ tags(:one) ], images(:two).tags
  end

  test "validations" do
    new_image = Image.new()
    assert !new_image.save

    assert_equal [
        I18n.translate( 'errors.messages.blank' ),
        I18n.translate( 'errors.messages.invalid' ),
      ],
      new_image.errors[:name]

    assert_equal I18n.translate( 'errors.messages.blank' ),
      new_image.errors[:title].join( '; ' )
  end

  test "add image" do
    new_image = Image.new(
      :album_id => albums(:devons).id,
      :name => 'cats03.jpg',
      :title => 'Котокот',
    )
    assert new_image.save
    assert_match %r/^\d{4}-\d\d-\d\d$/, new_image.reload.created_at.to_s
  end

  test "has photographer" do
    assert_equal images(:two).photographer, photographers(:one)
    assert_equal images(:one).photographer, nil
  end

  test "clean up thumb in album" do
    assert_equal albums(:devons).thumb, images(:one).name
    images(:one).destroy
    assert_equal albums(:devons).reload.thumb, nil
  end

  test "change_album" do
    prev_path = images(:one).file.path(:thumbs)
    assert_equal images(:one).reload.album, albums(:devons)
    images(:one).change_album albums(:myr)
    assert_equal images(:one).previous_thumb_path, prev_path
    assert_equal images(:one).reload.album, albums(:myr)
  end

  test "all_by_date" do
    assert_equal [ images(:one), images(:two) ],
      Image.all_by_date( images(:one).created_at ).order('images.name')

    assert_equal [ images(:one), images(:two) ],
      Image.all_by_date( images(:one).created_at.to_s ).order('images.name')
  end

  test "all_by_tag" do
    assert_equal [ images(:one), images(:two) ],
      Image.all_by_tag( tags(:one) ).order('images.name')
  end

  test "as_json" do
    assert_equal images(:one).as_json,
      {
        :name         => images(:one).name,
        :album        => images(:one).album.name,
        :title        => images(:one).title,
        :photographer => images(:one).photographer.nil? ? nil : images(:one).photographer.name,
        :added        => images(:one).created_at,
        :image_of_day => true,
      }
  end
end

# encoding: UTF-8
require 'test_helper'

class AlbumTest < ActiveSupport::TestCase
  fixtures :all

  test "has parent" do
    assert_equal albums(:cats).name, albums(:devons).parent.name
  end

  test "has subalbums" do
    assert_equal albums(:cats).subalbums, [ albums(:devons) ]
    assert_equal albums(:devons).subalbums, []
  end

  test "has images" do
    assert_equal albums(:devons).images.sort{ |a,b|
        result = a.created_at <=> b.created_at
        result = a.id <=> b.id if result.zero?
        result
      },
      [ images(:another_one), images(:one), images(:two) ]
  end

  test "has thumb_album" do
    assert_equal albums(:devons), albums(:cats).thumb_album
    assert_equal nil, albums(:devons).thumb_album
  end

  test "has thumb_image" do
    assert_equal albums(:devons).thumb_image, images(:one)
    assert_equal albums(:cats).thumb_image, nil
  end

  test "validations" do
    new_album = Album.new()
    assert !new_album.save

    assert_equal [
        I18n.translate( 'errors.messages.blank' ),
        I18n.translate( 'errors.messages.invalid' ),
      ],
      new_album.errors[:name]

    assert_equal I18n.translate( 'errors.messages.blank' ),
      new_album.errors[:title].join( '; ' )
  end

  test "add toplevel album" do
    new_album = Album.new(
      :name => 'album1',
      :title => 'Альбом1'
    )
    assert new_album.save
    assert !new_album.protected?
  end

  test "add child album" do
    new_album = Album.new(
      :parent_id => albums(:cats).id,
      :name => 'album2',
      :title => 'Альбом2'
    )
    assert new_album.save
    assert !new_album.protected?
    assert_equal new_album.password, nil
  end

  test "real_thumb" do
    assert_equal "#{albums(:devons).name}/#{albums(:devons).thumb}", albums(:cats).real_thumb
    assert_equal "#{albums(:devons).name}/#{albums(:devons).thumb}", albums(:devons).real_thumb
  end

  test "protected" do
    assert !albums(:cats).protected?, 'plain album'
    assert !albums(:devons).protected?, 'plain subalbum'
    assert albums(:protected).protected?, 'protected album'
    assert albums(:myr).protected?, 'subalbum for protected album'
  end

  test "add protected" do
    new_album = Album.new(
      :name => 'protected_album1',
      :title => 'p Альбом1',
      :password => 'test',
    )
    assert new_album.save, 'save'
    assert new_album.protected?, 'protected?'
    assert_equal new_album.password, Album::DONT_CHANGE_PASSWORD_FLAG
  end

  test "add protected subalbum" do
    new_album = Album.new(
      :parent_id => albums(:protected).id,
      :name => 'protected:album2',
      :title => 'p Альбом2',
    )
    assert new_album.save, 'save'
    assert new_album.protected?, 'protected?'
  end

  test "get_toplevel_albums_list" do
    assert_equal [ albums(:cats), albums(:protected) ], Album.get_toplevel_albums_list
  end

  test "public scope" do
    assert_equal [albums(:myr)], albums(:protected).subalbums.public_only
  end

  test "as_json" do
    assert_equal albums(:cats).as_json,
      {
        :name      => albums(:cats).name,
        :title     => albums(:cats).title,
        :protected => albums(:cats).protected,
        :folder    => albums(:cats).folder,
        :thumb     => albums(:cats).real_thumb,
        :added     => albums(:cats).created_at,
        :modified  => albums(:cats).updated_at,
        :hidden    => albums(:cats).hidden,
      }

    assert_equal albums(:protected).as_json,
      {
        :name      => albums(:protected).name,
        :title     => albums(:protected).title,
        :protected => true,
      }

    assert_equal albums(:myr).as_json,
      {
        :name      => albums(:myr).name,
        :title     => albums(:myr).title,
        :protected => true,
      }

    assert_equal albums(:myr).as_json({ no_protection: true }),
      {
        :name      => albums(:myr).name,
        :title     => albums(:myr).title,
        :protected => true,
        :folder    => albums(:myr).folder,
        :thumb     => albums(:myr).real_thumb,
        :added     => albums(:myr).created_at,
        :modified  => albums(:myr).updated_at,
        :hidden    => albums(:myr).hidden,
      }

    assert_equal albums(:hidden).as_json({ no_protection: true }),
      {
        :name      => albums(:hidden).name,
        :title     => albums(:hidden).title,
        :protected => albums(:hidden).protected,
        :folder    => albums(:hidden).folder,
        :thumb     => albums(:hidden).real_thumb,
        :added     => albums(:hidden).created_at,
        :modified  => albums(:hidden).updated_at,
        :hidden    => true,
      }
  end
end

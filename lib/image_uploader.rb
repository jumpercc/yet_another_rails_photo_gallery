# encoding: UTF-8
require 'album_protection'
require 'fileutils'

class Album < ActiveRecord::Base
  # to avoid "Expected x.rb to define X (LoadError)"
end

module ImageUploader
  def self.upload_images( base_folder, no_sign )
    album = get_upload_alum

    images_list = get_images_list( base_folder ).sort
    counter = 1
    total_images = images_list.size

    an_original_file = nil
    images_list.each do |image_name|
      puts "#{counter}/#{total_images}. " + File.basename( image_name )
      counter += 1

      new_image_name = uniq_image_name File.basename(image_name).downcase
      directory = File.dirname(image_name)
      if File.basename(image_name) != new_image_name
        File.rename( image_name, "#{directory}/#{new_image_name}" )
      end
      image_path = "#{directory}/#{new_image_name}"

      img = Image.create! \
        :album_id => album.id,
        :name => new_image_name,
        :title => new_image_name,
        :file => File.new( image_path, "r" )
      an_original_file = img.file.path(:original)

      File.delete image_path
    end

    if an_original_file
      an_original_file.sub!( %r{^(.+?/original)/#{UPLOAD_ALBUM[:name]}/.+$}, '\1' )
      FileUtils.rm_rf an_original_file
    end
  end

  ##############################################################################
  private

  PASSWORD_CHARS = [
    ('a'..'z').to_a,
    ('A'..'Z').to_a,
    ('0'..'9').to_a,
    '`', '~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_',
    '+', '|', '-', '=', '\\', ',', '.', '/', '<', '>', '?', ':', '"',
    ';', '{', '}', '[', ']', 
    ].flatten

  def self.generate_password
    ( 0...32 ).map { PASSWORD_CHARS[ rand(PASSWORD_CHARS.length) ] }.join
  end

  UPLOAD_FOLDER = '/tmp/upload'

  UPLOAD_ALBUM = {
    :name => 'upload',
    :title => 'Upload',
    :password => self.generate_password,
  }

  def self.get_images_list( base_folder )
    folder = base_folder + UPLOAD_FOLDER
    images_list = []
    Dir.foreach( folder ) do |file_name|
      if file_name.match %r{\.jpg$}i
        images_list.push folder + '/' + file_name
      end
    end

    images_list
  end

  def self.uniq_image_name(image_name)
    if Image.find_by_name( image_name ).nil?
      image_name
    else
      numbers = Image.where(
        'name LIKE ?', image_name.sub( %r{\.jpg$}, '.%.jpg' )
      ).collect do |image|
        image.name.match( %r{^.+?\.(\d+)\.jpg$} )[1].to_i
      end

      next_number = numbers.length.zero? \
        ? 1
        : numbers.sort.last + 1

      image_name.sub( %r{\.jpg$},
        '.' + sprintf( '%03d', next_number ) + '.jpg'
      )
    end
  end

  def self.get_upload_alum
    album = Album.find_by_name UPLOAD_ALBUM[:name]
    if album.nil?
      create_upload_album
    else
      album
    end
  end

  def self.create_upload_album
    Album.create! \
      :folder => false,
      :hidden => true,
      :name => UPLOAD_ALBUM[:name],
      :parent_id => nil,
      :password => Album.hash_password( UPLOAD_ALBUM[:password] ),
      :title => UPLOAD_ALBUM[:title]
  end
end

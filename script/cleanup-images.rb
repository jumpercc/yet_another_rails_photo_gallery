#!/usr/bin/env ruby

require 'find'
require 'sqlite3'

def get_fs_images( root, delete_files )
  fs_images = {}
  Find.find(root) do |path|
    dimension, album, image = path.split('/').slice 2..4
    if File.directory? path
      if path !~ %r!^#{Regexp.escape(root)}(/[^/]+)?/?$!
        fs_images[album] ||= {}
        fs_images[album][:_empty] ||= {}
        fs_images[album][:_empty][dimension] = path
      end
    else
      if path =~ /\.jpg$/
        fs_images[album] ||= {}
        fs_images[album][image] ||= {}
        fs_images[album][image][dimension] = path
      else
        puts "+ #{path}"
        File.delete path if delete_files
      end
    end
  end
  fs_images
end

def get_db_images(path)
  db_images = {}
  db = SQLite3::Database.new path
  query = <<-END_QUERY
    SELECT albums.name, albums.folder, images.name
    FROM albums
      LEFT JOIN images ON ( images.album_id = albums.id )
  END_QUERY
  db.execute(query) do |row|
    album, is_folder, image = *row
    db_images[album] ||= { _folder: is_folder == 't' }
    unless image.nil?
      db_images[album][image] = 1
    end
  end
  db_images
end

begin
  delete_files = !ARGV[0].nil?

  albums_root = 'public/albums'
  fs_images = get_fs_images albums_root, delete_files
  db_images = get_db_images 'db/production.sqlite3'

  fs_images.each_pair do |album,images|
    unless db_images.has_key? album
      images[:_empty].each_pair do |dimension,path|
        puts "+ #{path}"
        Dir.rmdir path if delete_files
      end
      next
    end
    images.each_pair do |image,dimensions|
      next if image.to_sym == :_empty
      unless db_images[album].has_key? image
        dimensions.each_pair do |dimension,path|
          puts "+ #{path}"
          File.delete path if delete_files
        end
      end
    end
  end

  db_images.each_pair do |album,images|
    next if images[:_folder]
    unless fs_images.has_key? album
      puts "- #{albums_root}/*/#{album}"
      next
    end
    images.each_key do |image|
      next if image.to_sym == :_folder
      unless fs_images[album].has_key? image
        puts "- #{albums_root}/*/#{album}/#{image}"
      end
    end
  end
end


require 'fileutils'

class Image < ActiveRecord::Base
  belongs_to :album
  has_many :tags, :through => :images_tags
  has_many :images_tags, :dependent=> :delete_all
  accepts_nested_attributes_for :images_tags
  has_one :image_of_day, :dependent=> :destroy
  belongs_to :photographer

  SIGN_FILE = Rails.application.config.root.to_s + '/lib/sign.jpg'
  has_attached_file :file,
    :styles => {
      :'1200x800' => { geometry: '1200x800>', watermark: SIGN_FILE },
      :'750x500'  => { geometry: '750x500>',  watermark: SIGN_FILE },
      :thumbs     => { geometry: '200x200>',  watermark: false }
    },
    :default_style   => :thumbs,
    :default_url     => '/image_stub.png',
    :storage         => :filesystem,
    :path            => ':rails_root/public/albums/:style/:album_name/:filename',
    :url             => '/albums/:style/:album_name/:filename',
    :processors      => [ :fit, :watermark ]

  Paperclip.interpolates :album_name do |attachment, style|
    attachment.instance.album.name
  end

  validates_attachment_content_type :file, :content_type => %w(image/jpeg image/jpg)

  validates_presence_of :name, :title
  validates_format_of :name, :with => /\A[-a-zA-Z0-9_'.]+\Z/
  validates_uniqueness_of :name

  attr_accessor :previous_thumb_path

  after_destroy :clean_up_album_thumb
  before_create :assign_date_to_created_at
  unless Rails.env == 'test'
    after_update :move_on_filesystem
  end

  def change_album(new_album)
    if self.album.id != new_album.id
      if !self.album.thumb.nil? && self.album.thumb == self.name
        self.album.thumb = nil
        self.album.save!
      end
      self.previous_thumb_path = self.file.path(:thumbs)
      self.album_id = new_album.id
      self.save!
    end
  end

  def self.all_by_date( date, asc_order=true )
    Image.where(
      "images.created_at" => date,
    ).eager_load(:album).where(
      "albums.protected" => false,
      "albums.hidden" => false,
    ).order("images.name#{ asc_order ? '' : ' DESC' }")
  end

  def self.all_by_tag(tag)
    tag.images.eager_load(:album).where(
      "albums.protected" => false,
      "albums.hidden" => false,
    )
  end

  def self.styles
    Image.attachment_definitions[:file][:styles].keys.collect{ |i| i.to_s }
  end

  def self.album_folder_prefix
    Rails.application.config.root.to_s + "/public/albums"
  end

  def as_json(options={})
    {
      :name  => self.name,
      :album => self.album.name,
      :title        => self.title,
      :photographer => self.photographer.nil? ? nil : self.photographer.name,
      :added        => self.created_at,
      :image_of_day => !self.image_of_day.nil?,
    }
  end

  ##############################################################################
  private

  def clean_up_album_thumb
    if self.album.thumb == self.name
      self.album.thumb = nil
      self.album.save!
    end
  end

  def assign_date_to_created_at
    self.created_at = Time.now.strftime "%Y-%m-%d"
  end

  def move_on_filesystem
    if !self.previous_thumb_path.nil?
      self.file.styles.each_key do |style|
        old_location =
          self.previous_thumb_path.gsub( /\/thumbs\//, "/#{style.to_s}/" )
        new_location = self.file.path(style)
        FileUtils.mv old_location, new_location
      end
      self.previous_thumb_path = nil
    end
  end
end

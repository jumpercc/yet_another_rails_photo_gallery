require 'digest/md5'
require 'fileutils'

class Album < ActiveRecord::Base
  has_many :images,
    :dependent => :destroy

  has_many :subalbums,
    :dependent => :destroy,
    :class_name => 'Album',
    :foreign_key => :parent_id,
    :inverse_of => :parent

  belongs_to :parent,
    :class_name => 'Album',
    :foreign_key => :parent_id

  belongs_to :thumb_album,
    :class_name => 'Album',
    :foreign_key => :thumb_from,
    :primary_key => :name

  has_one :thumb_image,
    :class_name => 'Image',
    :foreign_key => :name,
    :primary_key => :thumb

  validates_presence_of :name, :title
  validates_format_of :name, :with => /\A[-a-zA-Z0-9_':]+\Z/
  validates_uniqueness_of :name
  validate :name_starts_with_parent_name

  before_save :check_protected_up
  after_update :add_protected_down
  unless Rails.env == 'test'
    after_create :create_folders
    after_destroy :delete_folders
  end

  scope :public_only, -> { where( :hidden => false ) }
  scope :hidden_only, -> { where( :hidden => true ) }

  attr_accessor :password

  def real_thumb
    if self.folder? && !self.thumb_album.nil?
      self.thumb_album.real_thumb
    elsif !self.folder? && !self.thumb.nil?
      self.name + '/' + self.thumb
    else
      nil
    end
  end

  def get_page_number( child, items_per_page )
    finder = self.folder? ? self.subalbums : self.images
    Album._get_page_number finder, child, items_per_page
  end

  def self.get_top_level_page_number( child, items_per_page )
    finder = Album.where( :parent_id => nil, :hidden => false )
    _get_page_number( finder, child, items_per_page )
  end

  def self.get_toplevel_albums_list
      self.includes([:thumb_album]).where(
        :parent_id => nil, :hidden => false
      )
  end

  def password
    self.password_hash.nil? ? nil : DONT_CHANGE_PASSWORD_FLAG
  end

  def password=(value)
    if value != DONT_CHANGE_PASSWORD_FLAG
      if value == ''
        self.password_hash = nil
      else
        self.password_hash = self.class.hash_password value
      end
    end
  end

  def self.hash_password(password)
    Digest::MD5.hexdigest SALT + password
  end

  DONT_CHANGE_PASSWORD_FLAG = '*DO NOT CHANGE PASSWORD*'

  def as_json(options={})
    result = {
      :name      => self.name,
      :title     => self.title,
      :protected => self.protected,
    }

    if !self.protected || options[:no_protection]
      result.merge!( {
        :folder => self.folder,
        :thumb  => self.real_thumb,
        :added     => self.created_at,
        :modified  => self.updated_at,
        :hidden => self.hidden,
      } )
    end

    result
  end

  private

  SALT = Rails.application.secrets[:album_hash_salt]

  def self._get_page_number( finder, child, items_per_page )
    child_index = finder.order( 'created_at, name' ).index( child )
    child_index ||= 0
    ( ( child_index + 1 ) / items_per_page.to_f ).ceil
  end

  def check_protected_up
    if !self.password.nil?
      self.protected = true
    elsif !self.parent.nil? && self.parent.protected?
      self.protected = true
    else
      self.protected = false
    end

    true
  end

  def add_protected_down
    if self.protected?
      self.subalbums.each do |subalbum|
        if !subalbum.protected?
          subalbum.protected = true
          subalbum.save!
        end
      end
    else
      self.subalbums.each do |subalbum|
        if subalbum.protected? && subalbum.password.nil?
          subalbum.protected = false
          subalbum.save!
        end
      end
    end
  end

  def name_starts_with_parent_name
    if self.parent.nil?
      true
    else
      self.name.match( %r{\A#{self.parent.name}:.+\Z} )
    end
  end

  def create_folders
    Image.styles.each do |style|
      folder_name = [ Image.album_folder_prefix, style, self.name ].join '/'
      if !File.exists? folder_name
        Dir.mkdir folder_name
      end
    end
  end

  def delete_folders
    Image.styles.each do |style|
      folder_name = [ Image.album_folder_prefix, style, self.name ].join '/'
      if File.exists? folder_name
        FileUtils.rm_rf folder_name
      end
    end
  end
end

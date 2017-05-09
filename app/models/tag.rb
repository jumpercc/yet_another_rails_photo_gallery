class Tag < ActiveRecord::Base
  has_many :images_tags, :dependent=> :delete_all
  has_many :images, :through => :images_tags

  validates_presence_of :tag
  validates_uniqueness_of :tag

  def self.all_with_images_count
    self.select(
      'tags.*, COUNT(*) AS images_count'
    ).joins( # a bug: returns count=1 when no images for tag
      'LEFT JOIN images_tags ON ( tags.id = images_tags.tag_id OR images_tags.tag_id IS NULL )'
    ).group( 'tag' ).order( 'tag' )
  end

  def as_json(options={})
    result = {
      :name  => self.tag,
    }

    if self.respond_to? :images_count
      result[:images_count] = self.images_count
    end

    result
  end
end

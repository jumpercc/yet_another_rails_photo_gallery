class Tag < ActiveRecord::Base
  has_many :images, :through => :images_tags
  has_many :images_tags, :dependent=> :delete_all

  validates_presence_of :tag
  validates_uniqueness_of :tag

  def self.all_with_images_count
    self.select(
      'tags.*, COUNT(*) AS images_count'
    ).joins(
      'JOIN images_tags ON ( tags.id = images_tags.tag_id )'
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

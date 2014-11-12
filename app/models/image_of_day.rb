class ImageOfDay < ActiveRecord::Base
  belongs_to :image

  validates_presence_of :day, :image_id
  validates_uniqueness_of :day

  def self.mark_as_image_of_day( date, image )
    image_of_day = ImageOfDay.find_by_day date
    if image_of_day.nil?
      image_of_day = ImageOfDay.new :day => date, :image => image
    else
      image_of_day.image = image
    end
    image_of_day.save!
  end

  def self.list( asc_order = true )
    ImageOfDay.all.eager_load(:image).joins(
      'JOIN albums ON ( albums.id = images.album_id )'
    ).where(
      "albums.protected" => false,
      "albums.hidden" => false,
    ).references(:album).order("day#{ asc_order ? '' : ' DESC'}")
  end

  def as_json(options={})
    {
      :day          => self.day.to_s,
      :name         => self.image.name,
      :album        => self.image.album.name,
    }
  end
end

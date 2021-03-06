class Photographer < ActiveRecord::Base
  has_many :images

  validates_presence_of :name
  validates_uniqueness_of :name
end

require 'digest/md5'

class User < ActiveRecord::Base
  attr_writer :password

  validates_presence_of :name, :password_hash, :salt
  validates_uniqueness_of :name

  def password=(value)
    self.salt = get_salt
    self.password_hash = self.class.hash_password value, salt
  end

  def self.autorized?(cookies)
    user_name = cookies.signed[:user]
    !user_name.nil? && !User.find_by_name( user_name ).nil?
  end

  private

  def self.hash_password( password, salt )
    Digest::MD5.hexdigest salt + password
  end

  def get_salt
    self.object_id.to_s + rand.to_s
  end
end

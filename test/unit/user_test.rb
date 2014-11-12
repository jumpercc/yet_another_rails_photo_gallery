require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "create new" do
    user = User.new :name => 'user3'
    user.password = 'pass'
    assert user.save
  end

  test "get by name" do
    assert_equal User.find_by_name( users(:user1).name ), users(:user1)
  end
end

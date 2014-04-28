class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.string :usernameFrom
      t.string :usernameTo
      end
  end
end

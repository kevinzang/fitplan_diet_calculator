class CreateFriendRequests < ActiveRecord::Migration
  def change
    create_table :friend_requests do |t|
      t.string :usernameFrom
      t.string :usernameTo
      t.boolean :friendStatus
    end
  end
end

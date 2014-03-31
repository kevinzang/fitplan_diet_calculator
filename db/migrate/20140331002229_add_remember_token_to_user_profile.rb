class AddRememberTokenToUserProfile < ActiveRecord::Migration
  def change
  	add_column :user_profiles, :remember_token, :string
  	add_index :user_profiles, :remember_token
  end
end

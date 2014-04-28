class CreateUsernameIndex < ActiveRecord::Migration
  def change
  	 add_index(:user_profiles, :username) 
  end
end

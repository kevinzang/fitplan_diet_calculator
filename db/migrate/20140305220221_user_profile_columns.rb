class UserProfileColumns < ActiveRecord::Migration
  def change
  	add_column(UserProfile, :username, :string)
  	add_column(UserProfile, :password, :string)
  	add_column(UserProfile, :height, :integer)
  	add_column(UserProfile, :weight, :integer)
  	add_column(UserProfile, :desired_weight, :integer)
  	add_column(UserProfile, :age, :integer)
  	add_column(UserProfile, :foods, :integer)
  	add_column(UserProfile, :calories, :integer)
  	add_column(UserProfile, :entries, :text)
  end
end

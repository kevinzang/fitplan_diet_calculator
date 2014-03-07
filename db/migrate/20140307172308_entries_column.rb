class EntriesColumn < ActiveRecord::Migration
  def change
  	remove_column(UserProfile, :foods, :integer)
  	remove_column(UserProfile, :calories, :integer)
  end
end

class AddColumnsToUserProfile < ActiveRecord::Migration
  def change
    add_column :user_profiles, :activity_level, :integer
    add_column :user_profiles, :weight_change_per_week_goal, :float
  end
end
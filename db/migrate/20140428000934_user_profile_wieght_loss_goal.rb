class UserProfileWieghtLossGoal < ActiveRecord::Migration
  def change
  	add_column(UserProfile, :weight_loss_goal, :integer)
  end
end

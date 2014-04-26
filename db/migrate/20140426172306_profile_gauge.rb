class ProfileGauge < ActiveRecord::Migration
  def change
  	add_column(UserProfile, :gauge_level, :integer)
  	add_column(UserProfile, :last_login, :string)
  end
end

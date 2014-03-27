class ChangeCaloriesFoodSearch < ActiveRecord::Migration
  def change
  	remove_column :food_searches, :calories, :integer
    add_column :food_searches, :calories, :string
  end
end

class UpdateFoodSearch < ActiveRecord::Migration
  def change
  	add_column :food_searches, :calories, :integer
  	add_column :food_searches, :date, :string
  	add_column :food_searches, :serving, :string
  end
end

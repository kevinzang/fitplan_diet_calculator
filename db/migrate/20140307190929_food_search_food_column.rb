class FoodSearchFoodColumn < ActiveRecord::Migration
  def change
  	add_column(FoodSearch, :food, :string)
  end
end

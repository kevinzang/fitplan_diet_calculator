class AddSearchedField < ActiveRecord::Migration
  def change
  	add_column(FoodSearch, :searched, :boolean)
  end
end

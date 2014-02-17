class CreateFoodSearches < ActiveRecord::Migration
  def change
    create_table :food_searches do |t|
      t.integer :num
      t.string :link

      t.timestamps
    end
  end
end

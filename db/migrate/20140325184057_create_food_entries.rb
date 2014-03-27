class CreateFoodEntries < ActiveRecord::Migration
  def change
    create_table :food_entries do |t|
      t.string :username
      t.string :food
      t.integer :calories
      t.string :date
      t.string :serving
      t.integer :numservings

      t.timestamps
    end

    remove_column :user_profiles, :entries, :text
    add_column :user_profiles, :gender, :string
  end
end

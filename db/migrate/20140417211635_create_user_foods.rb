class CreateUserFoods < ActiveRecord::Migration
  def change
    create_table :user_foods do |t|
      t.string :username
      t.string :food
      t.integer :calories
      t.string :serving

      t.timestamps
    end
  end
end

class CreateWeightEntries < ActiveRecord::Migration
  def change
    create_table :weight_entries do |t|
      t.string :username
      t.string :date
      t.integer :weight

      t.timestamps
    end
  end
end

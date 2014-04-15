class CreateWorkoutEntries < ActiveRecord::Migration
  def change
    create_table :workout_entries do |t|
      t.string :username
      t.string :activity
      t.integer :minutes
      t.string :date

      t.timestamps
    end
  end
end

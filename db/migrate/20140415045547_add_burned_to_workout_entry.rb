class AddBurnedToWorkoutEntry < ActiveRecord::Migration
  def change
  	add_column :workout_entries, :burned, :integer
  end
end

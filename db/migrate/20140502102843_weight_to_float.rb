class WeightToFloat < ActiveRecord::Migration
  def self.up
    change_column :weight_entries, :weight, :float
  end

  def self.down
    change_column :weight_entries, :weight, :integer
  end
end

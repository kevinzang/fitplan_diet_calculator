class WeightEntry < ActiveRecord::Base
  validates :username, :presence => true
  validates :date, :presence => true
  validates :weight, :presence => true
  validates :weight, :numericality => {:greater_than_or_equal_to => 0}
  validates :weight, :numericality => {:less_than_or_equal_to => 1000}
end
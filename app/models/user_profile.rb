class UserProfile < ActiveRecord::Base
	serialize :entries, Array
end

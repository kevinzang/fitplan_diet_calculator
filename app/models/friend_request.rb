class FriendRequest < ActiveRecord::Base

	before_update :checkFriendStatus

	def checkFriendStatus()
		if (self.file_status_changed? and self.file_status) 		
			Friendships.create(usernameTo:usernameTo, usernameFrom:usernameFrom) 
			Friendships.create(usernameTo:usernameFrom, usernameFrom:usernameTo) 
		end
	end
end 
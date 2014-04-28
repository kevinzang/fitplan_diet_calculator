class FriendRequest < ActiveRecord::Base

	before_update :checkFriendStatus

	def checkFriendStatus()
		if (self.friendStatus && self.friendStatus_changed?) 		
			Friendship.create(usernameTo:usernameTo, usernameFrom:usernameFrom) 
			Friendship.create(usernameTo:usernameFrom, usernameFrom:usernameTo) 
		end
	end
end 
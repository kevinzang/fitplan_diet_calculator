require 'json'

class FriendRequestsController < ApplicationController
	include ApplicationHelper

	def create_request()
		if !valid_json?(["username"])
			return render(:json=>{}, status:500)
		end
		@username = params[:username] #this is from the form
		@usernameFrom = getUser(cookies[:remember_token])
		if @username == @usernameFrom
			return render(:json=>{"result"=>'Cannot Friend Yourself'}, status:200)
		elsif (UserProfile.find_by(username: @username))
			FriendRequest.find_or_create_by(usernameTo: @username, usernameFrom: @usernameFrom, friendStatus: false)
			return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
		else
			return render(:json=>{"result"=>'User Does Not Exist'}, status:200)
		end
	end

	def accept_request()
		if !valid_json?(["friend"])
			return render(:json=>{}, status:500)
		end
		usernameFrom = params[:friend] #this is from the picture
		usernameTo = getUser(cookies[:remember_token])
		returnedUserMatch = FriendRequest.where(usernameTo:  usernameTo, usernameFrom:  usernameFrom).first
		returnedUserMatch.friendStatus = true
		returnedUserMatch.save()
		FriendRequest.delete(usernameTo: userTo, username: userFrom)

		return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
	end

	def hot_button_create_request()
		puts "THE WORLD HAS ENDED"
		username = getUser(cookies[:remember_token])
		if username == nil
			return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
		end
		@mainuser = UserProfile.find_by(username:username)
		#don't worry about dynamic goal weight()
		@closest_match = nil
		tempDif = 1000000
		user_weight_loss = 2000000
		if @mainuser.weight != nil && @mainuser.desired_weight != nil
			user_weight_loss = @mainuser.weight - @mainuser.desired_weight
		end
		all_users = UserProfile.all
		for user in all_users
			if ((user.username != @mainuser.username) && (user.desired_weight != nil) && (user.weight != nil))
				cur_loss = user.weight - user.desired_weight
				if ((user_weight_loss - cur_loss).abs < tempDif)
					tempDif = (user_weight_loss - cur_loss).abs
					@closest_match = user
				end
			end
		end

		if (@closest_match != nil)
			FriendRequest.find_or_create_by(usernameTo: @closest_match, usernameFrom: @mainuser, friendStatus: false)
		end 
		return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
	end
end

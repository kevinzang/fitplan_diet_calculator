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
		elsif Friendship.find_by(usernameTo:@username, usernameFrom:@usernameFrom)
			return render(:json=>{"result"=>"#{@username} is already your friend"}, status:200)
		elsif FriendRequest.find_by(usernameTo:@usernameFrom, usernameFrom:@username)
			return render(:json=>{"result"=>"#{@username} has already sent a request to you"}, status:200)
		elsif UserProfile.find_by(username:@username)
			FriendRequest.find_or_create_by(usernameTo: @username, usernameFrom: @usernameFrom, friendStatus: false)
			return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
		else
			return render(:json=>{"result"=>'User Does Not Exist'}, status:200)
		end
	end

	def delete_friend()
		if !valid_json?(["friend"])
			return render(:json=>{}, status:500)
		end
			@usernameDel = params[:friend] #this is from the Picture onClick!!!!
			@username = getUser(cookies[:remember_token])
			way1 = Friendship.find_by(usernameTo:@username, usernameFrom:@usernameDel)
			way2 = Friendship.find_by(usernameTo:@usernameDel, usernameFrom:@username)
			pending = FriendRequest.find_by(usernameTo: @username, usernameFrom:  @usernameDel)
		if (pending != nil)
			pending.delete #this should be redundant
		elsif (way1 || way2)
			way1.delete()
			way2.delete()
			return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
		end
		return render(:json=>{"result"=>'User Does Not Exist'}, status:200)
	end



	def accept_request()
		if !valid_json?(["friend"])
			return render(:json=>{}, status:500)
		end
		usernameFrom = params[:friend] #this is from the picture
		usernameTo = getUser(cookies[:remember_token])
		returnedUserMatch = FriendRequest.where(usernameTo:  usernameTo, usernameFrom:  usernameFrom).first
		returnedUserMatch.friendStatus = true #check this
		returnedUserMatch.save()
		toDelete = FriendRequest.find_by(usernameTo:  usernameTo, usernameFrom:  usernameFrom)
		toDelete.delete()

		return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
	end

	def hot_button_create_request()
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
			if user.username != @mainuser.username &&
				user.desired_weight != nil &&
				user.weight != nil &&
				Friendship.find_by(usernameTo:@mainuser.username, usernameFrom:user.username) == nil &&
				FriendRequest.find_by(usernameTo:user.username, usernameFrom:@mainuser.username) == nil &&
				FriendRequest.find_by(usernameTo:@mainuser.username, usernameFrom:user.username) == nil	
				cur_loss = user.weight - user.desired_weight
				if ((user_weight_loss - cur_loss).abs < tempDif)
					tempDif = (user_weight_loss - cur_loss).abs
					@closest_match = user
				end
			end
		end

		if (@closest_match != nil)
			FriendRequest.find_or_create_by(usernameTo: @closest_match.username, usernameFrom: @mainuser.username, friendStatus: false)
		end 
		return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
	end
end

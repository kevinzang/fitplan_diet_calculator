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
			puts "case to = from"
			return render(:json=>{"result"=>'Cannot Friend Yourself'}, status:200)
		elsif (UserProfile.find_by(username: @username))
			puts "case all green"
			FriendRequest.find_or_create_by(usernameTo: @username, usernameFrom: @usernameFrom, friendStatus: false)
			return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
		else
			puts "case user not existant"
			return render(:json=>{"result"=>'User Does Not Exist'}, status:200)
		end
	end

	def accept_request()
		if !valid_json?(["friend"])
			return render(:json=>{}, status:500)
		end
		usernameFrom = params[:friend] #this is from the URL
		usernameTo = getUser(cookies[:remember_token])
		returnedUserMatch = FriendRequest.where(usernameTo:  usernameTo, usernameFrom:  usernameFrom).first
		returnedUserMatch.friendStatus = true
		returnedUserMatch.save()
		return render(:json=>{"result"=>UserProfile::SUCCESS}, status:200)
	end

	def hot_button_create_request()
		@username = params[:username] #this is from the form ???
		@usernameFrom = getUser(cookies[:remember_token])
		#create a difference in the Db first!!!
	end
			

end
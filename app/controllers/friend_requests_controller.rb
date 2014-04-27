class FriendRequestsController < ApplicationController
include ApplicationHelper

	def create_request()
		@username = params[:username] #this is from the form
		@usernameFrom = getUser(cookies[:remember_token])

		if @username == @usernameFrom
			flash.now[:alert] = 'Cannot Friend Yourself'
			redirect_to '/profile'
		elsif (UserProfile.find_by(username: @username))
			FriendRequest.find_or_create_by(usernameTo: @username, usernameFrom: @usernameFrom, friendStatus: false)
		else
			flash.now[:alert] = 'User Does Not Exist'
		end 

		redirect_to '/profile'
		#either render or redirect
	end

	def accept_request()
		usernameTo = params[:username] #this is from the URL
		usernameFrom = getUser(cookies[:remember_token])
		returnedUserMatch = FriendRequest.where(usernameTo:  usernameTo, usernameFrom:  usernameFrom).first
		returnedUserMatch.friendStatus = true
		returnedUserMatch.save()
		redirect_to '/profile'
		#either render or redirect
	end

	def hot_button_create_request()
		@username = params[:username] #this is from the form ???
		@usernameFrom = getUser(cookies[:remember_token])
		#create a difference in the Db first!!!
	end
			

end
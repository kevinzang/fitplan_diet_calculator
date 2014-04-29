require 'spec_helper'

describe "Friends Unit Tests" do
	before(:each) {
		UserProfile.reset()
		FriendRequest.delete_all()
		Friendship.delete_all()
	}
	after(:each) {
		UserProfile.reset()
		FriendRequest.delete_all()
		Friendship.delete_all()
	}
	session = {'CONTENT_TYPE'=>'application/json',
		'ACCEPT' => 'application/json'}
	describe "sending friend requests" do
		it "should create a friend request" do
			UserProfile.signup("a", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("b", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"a"}
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 1
			FriendRequest.find_by(usernameFrom:"b", usernameTo:"a").friendStatus.should == false
			FriendRequest.find_by(usernameFrom:"a", usernameTo:"b").should == nil
		end
		it "should not create a duplicate friend request" do
			UserProfile.signup("a", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("b", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"a"}
			post '/profile/create_request', req.to_json, session
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 1
			FriendRequest.find_by(usernameFrom:"b", usernameTo:"a").friendStatus.should == false
			FriendRequest.find_by(usernameFrom:"a", usernameTo:"b").should == nil
		end
		it "should not friend yourself" do
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"a"}
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 0
		end
		it "should not friend a nonexistant user" do
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"b"}
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 0
		end
		it "should not friend someone who is already a friend" do
			UserProfile.signup("b", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			Friendship.create(usernameTo:"a", usernameFrom:"b")
			Friendship.create(usernameTo:"b", usernameFrom:"a")
			req = {"username"=>"b"}
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 0
		end
		it "should not friend someone who already requested to be your friend" do
			UserProfile.signup("b", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			FriendRequest.create(usernameTo:"a", usernameFrom:"b")
			req = {"username"=>"b"}
			post '/profile/create_request', req.to_json, session
			FriendRequest.all.count.should == 1
		end
	end
	describe "accepting friend requests" do
		it "should accept a friend request" do
			UserProfile.signup("b", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			FriendRequest.create(usernameFrom:"b", usernameTo:"a", friendStatus:false)
			req = {"friend"=>"b"}
			post '/profile/accept_request', req.to_json, session
			FriendRequest.all.count.should == 0
			Friendship.all.count.should == 2
			Friendship.find_by(usernameFrom:"b", usernameTo:"a").should_not == nil
			Friendship.find_by(usernameFrom:"a", usernameTo:"b").should_not == nil
		end
	end
	describe "finding a new friend" do
		before(:each) {
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			a = UserProfile.find_by(username:"a")
			a.weight = 160
			a.desired_weight = 155
			a.save()
		}
		req = {}
		it "should not find yourself" do
			post '/profile/find_friend', req.to_json, session
			assigns[:closest_match].should == nil
		end
		it "should not find someone who is already a friend" do
			UserProfile.create(username:"b", weight:160, desired_weight:155)
			Friendship.create(usernameTo:"a", usernameFrom:"b")
			Friendship.create(usernameTo:"b", usernameFrom:"a")
			post '/profile/find_friend', req.to_json, session
			assigns[:closest_match].should == nil
		end
		it "should find closest match" do
			UserProfile.create(username:"b", weight:160, desired_weight:154)
			UserProfile.create(username:"c", weight:160, desired_weight:153)
			post '/profile/find_friend', req.to_json, session
			assigns[:closest_match].username.should == "b"
		end
		it "should not error if there are users with incomplete profile form" do
			UserProfile.create(username:"b")
			UserProfile.signout("0")
			UserProfile.signup("c", "secret", "1")
			cookies[:remember_token] = "1"
			post '/profile/find_friend', req.to_json, session
			assigns[:closest_match].should == nil
		end
	end
	describe "deleting a friend" do
		it "should delete friend" do
			Friendship.create(usernameTo:"a", usernameFrom:"b")
			Friendship.create(usernameTo:"b", usernameFrom:"a")
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "", "0")
			req = {"friend"=>"b"}
			post '/profile/delete_friend', req.to_json, session
			Friendship.all.length.should == 0
		end
	end

end
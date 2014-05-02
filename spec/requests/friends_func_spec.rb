require 'spec_helper'

describe "Friends Functional Tests" do
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
			ActiveSupport::JSON.decode(response.body)["result"].should == UserProfile::SUCCESS
    end
		it "should not friend yourself" do
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"a"}
			post '/profile/create_request', req.to_json, session
			ActiveSupport::JSON.decode(response.body)["result"].should_not == UserProfile::SUCCESS
		end
		it "should not friend a nonexistant user" do
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			req = {"username"=>"b"}
			post '/profile/create_request', req.to_json, session
			ActiveSupport::JSON.decode(response.body)["result"].should_not == UserProfile::SUCCESS
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
			ActiveSupport::JSON.decode(response.body)["result"].should_not == UserProfile::SUCCESS
		end
		it "should not friend someone who already requested to be your friend" do
			UserProfile.signup("b", "secret", "1")
			UserProfile.signout("1")
			UserProfile.signup("a", "secret", "0")
			cookies[:remember_token] = "0"
			FriendRequest.create(usernameTo:"a", usernameFrom:"b")
			req = {"username"=>"b"}
			post '/profile/create_request', req.to_json, session
			ActiveSupport::JSON.decode(response.body)["result"].should_not == UserProfile::SUCCESS
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
			ActiveSupport::JSON.decode(response.body)["result"].should == UserProfile::SUCCESS
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
		it "should find closest match" do
			UserProfile.create(username:"b", weight:160, desired_weight:154)
			UserProfile.create(username:"c", weight:160, desired_weight:153)
			post '/profile/find_friend', req.to_json, session
			ActiveSupport::JSON.decode(response.body)["result"].should == UserProfile::SUCCESS
		end
  end
# error from assigns
	describe "getting the pending requests and friends in /profile" do
		it "should have correct @pending_out, @pending_in, and @accepted" do
			cookies[:remember_token] = "0"
			UserProfile.signup("b", "", "0")
			UserProfile.signout("0")
			UserProfile.signup("a", "", "0")
			UserProfile.create(username:"b", password:"")
			FriendRequest.create(usernameFrom:"a", usernameTo:"b", friendStatus:false)
			get '/profile'
      UserProfile.print('asdf')
			assigns[:pending_out][0].usernameTo.should == "b"
			assigns[:pending_in].length.should == 0
			assigns[:accepted].length.should == 0
			UserProfile.signout("0")
			UserProfile.login("b", "", "0")
			get '/profile'
			assigns[:pending_in][0].usernameFrom.should == "a"
			assigns[:pending_out].length.should == 0
			assigns[:accepted].length.should == 0
			req = {"friend"=>"a"}
			post '/profile/accept_request', req.to_json, session
			get '/profile'
			assigns[:pending_in].length.should == 0
			assigns[:pending_out].length.should == 0
			assigns[:accepted].length.should == 1
			assigns[:accepted][0].usernameFrom.should == "a"
			UserProfile.signout("0")
			UserProfile.login("a", "", "0")
			get '/profile'
			assigns[:pending_in].length.should == 0
			assigns[:pending_out].length.should == 0
			assigns[:accepted].length.should == 1
			assigns[:accepted][0].usernameFrom.should == "b"
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
			ActiveSupport::JSON.decode(response.body)["result"].should == UserProfile::SUCCESS
		end
  end
end

require 'spec_helper'
require File.expand_path("../../../app/controllers/UserProfileModel", __FILE__)
require File.expand_path("../../../app/controllers/FoodSearchModel", __FILE__)
require 'date'
require 'json'

describe "Fitplan Functional Tests" do
	before(:each) {
		UserProfileModel.reset()
	}
	after(:each) {
		UserProfileModel.reset()
	}
	session = {'CONTENT_TYPE'=>'application/json', 'ACCEPT' => 'application/json'}
	describe "add new user" do
		it "should add new user" do
			UserProfileModel.isRegistered?("kevin").should == false
			req = {"username"=>"kevin", "password"=>"secret"}
			resp = {"result"=>UserProfileModel::SUCCESS}
			post '/signup_submit', req.to_json, session
			response.body.should == resp.to_json
			UserProfileModel.isRegistered?("kevin").should == true
		end
	end
	describe "log in returning user" do
		it "should log in user" do
			UserProfileModel.signup("kevin", "secret")
			req = {"username"=>"kevin", "password"=>"secret"}
			resp = {"result"=>UserProfileModel::SUCCESS}
			post '/login_submit', req.to_json, session
			response.body.should == resp.to_json
		end
	end
	describe "submit profile form" do
		it "should submit profile" do
			UserProfileModel.signup("a", "secret")
			req = {"feet"=>"5", "inches"=>"0", "weight"=>"150",
				"desired_weight"=>"140", "age"=>"20"}
			resp = {"result"=>UserProfileModel::SUCCESS}
			post '/profile_form/submit', req.to_json, session
			response.body.should == resp.to_json
		end
	end
	describe "search for food to add" do
		it "should set @food and @results" do
			post '/profile/add_food', {'food' => "mashed potatoes"}
			assigns(:food).should == "mashed potatoes"
			assigns(:results).length.should > 0
			assigns(:results)[0].should == "Potatoes, Mashed, Home-prepared, Whole Milk And Margarine Added"
		end
    end
    describe "get calorie for food" do
		it "should return the calorie" do
			FoodSearchModel.search("mashed potatoes")
			req = {"num"=>"5"}
			resp = {"calorie"=>"204"}
			post '/profile/add_food/get_calorie', req.to_json, session
			response.body.should == resp.to_json
		end
    end
    describe "add food" do
		it "should add the food entry" do
			UserProfileModel.signup("a", "secret")
			entries = UserProfileModel.getEntries("a")
			entries.length.should == 0
			food_name = FoodSearchModel.search("mashed potatoes")[5]
			req = {"num" => "5", "calorie" => "204"}
			resp = {"result" => UserProfileModel::SUCCESS}
			post '/profile/add_food/get_calorie/add', req.to_json, session
			entries = UserProfileModel.getEntries("a")
			entries.length.should == 1
			entries[0][0].should == food_name
			entries[0][1].should == "204"
			entries[0][2].should == Date.today.to_s
		end
	end
	describe "delete food" do
		it "should delete the entries" do
			UserProfileModel.signup("a", "secret")
			UserProfileModel.addFood("a", "chicken pot pie", "150", "2014-01-01")
			UserProfileModel.addFood("a", "chicken pot pie", "150", "2014-01-01")
			entries = UserProfileModel.getEntries("a")
			entries.length.should == 2
			req = {"delete" => ["chicken pot pie"].to_s}
			resp = {"result" => UserProfileModel::SUCCESS}
			post '/profile/delete_food', req.to_json, session
			entries = UserProfileModel.getEntries("a")
			entries.length.should == 1
		end
	end
	describe "getting today's entries" do
		@today = Date.today.to_s
		@entries = UserProfileModel.getEntriesByDate("a", @today)
		if @entries.class != Array
			@message = @entries
		else
			@message = "You have #{@entries.length} entries for #{@today}."
		end
		it "should set @today and @entries" do
			UserProfileModel.signup("a", "secret")
			UserProfileModel.addFood("a", "chicken pot pie", "150", Date.today.to_s)
			UserProfileModel.addFood("a", "ice cream", "175", (Date.today-1).to_s)
			get '/profile'
			assigns(:today).should == Date.today.to_s
			todays_entries = assigns(:entries)
			todays_entries.length.should == 1
			todays_entries[0][0].should == "chicken pot pie"
			todays_entries[0][1].should == "150"
			todays_entries[0][2].should == Date.today.to_s
		end
	end
	describe "getting the workout plan" do
		it "should set @target, @intake, and @recommended" do
			UserProfileModel.signup("a", "secret")
			UserProfileModel.addFood("a", "chicken pot pie", "1000", Date.today.to_s)
			UserProfileModel.addFood("a", "ice cream", "100", (Date.today-1).to_s)
			UserProfileModel.addFood("a", "dragon tail", "2000", Date.today.to_s)
			get '/profile/workout'
			target = UserProfileModel.getTarget("")
			assigns(:target).should == 2000
			assigns(:intake).should == 3000
			assigns(:recommended).should == 120
		end
    end
end

require 'spec_helper'
require File.expand_path("../../../app/controllers/UserProfileModel", __FILE__)
require File.expand_path("../../../app/controllers/FoodSearchModel", __FILE__)
require 'date'

describe "Fitplan Unit Tests" do
	before(:each) {
		UserProfileModel.reset()
	}
	after(:each) {
		UserProfileModel.reset()
	}
	describe "add new user" do
		it "should not have a blank username" do
			result = UserProfileModel.signup("", "secret")
			result.should == UserProfileModel::ERR_BAD_USERNAME
		end
		it "should not have a username that is too long" do
			name = "a"*(UserProfileModel::MAX_USERNAME_LENGTH+1)
			UserProfileModel.signup(name, "secret").should == UserProfileModel::ERR_BAD_USERNAME
		end
		it "can have a blank password" do
			UserProfileModel.signup("kevin", "").should == UserProfileModel::SUCCESS
		end
		it "should not have a password that is too long" do
			pass = "a"*(UserProfileModel::MAX_PASSWORD_LENGTH+1)
			UserProfileModel.signup("kevin", pass).should == UserProfileModel::ERR_BAD_PASSWORD
		end
		it "should not add an already registered user" do
			UserProfileModel.signup("kevin", "secret").should == UserProfileModel::SUCCESS
			UserProfileModel.signup("kevin", "secret").should == UserProfileModel::ERR_USER_EXISTS
		end
	end
	describe "log in returning user" do
		it "should fail if user does not exist" do
			UserProfileModel.login("kevin", "secret").should == UserProfileModel::ERR_BAD_CREDENTIALS
		end
		it "should fail if password is incorrect" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.login("kevin", "Secret").should == UserProfileModel::ERR_BAD_CREDENTIALS
		end
		it "should work if username/password combo is correct" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.login("kevin", "secret").should == UserProfileModel::SUCCESS
		end
	end
	describe "submit profile form" do
		before(:each) {
			UserProfileModel.signup("kevin", "secret")
		}
		it "should fail if fields contain negative values" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155", "desired_weight"=>"150", "age"=>"-20"}
			UserProfileModel.setProfile("kevin", fields.keys, fields).should_not == UserProfileModel::SUCCESS
		end
		it "should fail if fields contain words" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155", "desired_weight"=>"150", "age"=>"twenty"}
			UserProfileModel.setProfile("kevin", fields.keys, fields).should_not == UserProfileModel::SUCCESS
		end
		it "should work if all fields are either blank or non-negative integers" do
			fields = {"feet"=>"5", "inches"=>"0", "weight"=>"155", "desired_weight"=>"150", "age"=>"20"}
			UserProfileModel.setProfile("kevin", fields.keys, fields).should == UserProfileModel::SUCCESS
		end
	end
	describe "search for food to add" do
		it "should return the search results" do
			results = FoodSearchModel.search("mashed potatoes")
			results.length.should > 0
			results[0].should == "Potatoes, Mashed, Home-prepared, Whole Milk And Margarine Added"
		end
		it "should return 'No Results Found' if no search results are found" do
			results = FoodSearchModel.search("ore no imouto ga konnani kawaii wake ga nai")
			results.length.should > 0
			results[0].should == "No Results Found"
		end
    end
    describe "get calorie for food" do
		it "should return the calorie" do
			results = FoodSearchModel.search("mashed potatoes")
			results.length.should > 5
			results[5].should == "Potatoes, Mashed, Dehydrated, Prepared From Flakes - Without Milk, Whole Milk And Butter Add"
			FoodSearchModel.getCalorie(5).should == "204"
		end
    end
    describe "add food" do
		it "should fail if user is not registered" do
			UserProfileModel.addFood("kevin", "chicken", "150", "2014-01-01").should_not == UserProfileModel::SUCCESS
		end
		it "should work if user is registered" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.addFood("kevin", "chicken", "150", "2014-01-01").should == UserProfileModel::SUCCESS
			entries = UserProfileModel.getEntries("kevin")
			entries.length.should == 1
			entries[0][0].should == "chicken"
			entries[0][1].should == "150"
			entries[0][2].should == "2014-01-01"
		end
	end
	describe "delete food" do
		it "should fail if user is not registered" do
			UserProfileModel.deleteFood("kevin", ["chicken"]).should_not == UserProfileModel::SUCCESS
		end
		it "should not have any effect if food not in list" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.addFood("kevin", "chicken", "150", "2014-01-01")
			UserProfileModel.deleteFood("kevin", ["beans"]).should == UserProfileModel::SUCCESS
			entries = UserProfileModel.getEntries("kevin")
			entries.length.should == 1
			entries[0][0].should == "chicken"
			entries[0][1].should == "150"
			entries[0][2].should == "2014-01-01"
		end
		it "should delete entries one at a time" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.addFood("kevin", "chicken pot pie", "150", "2014-01-01")
			UserProfileModel.addFood("kevin", "chicken pot pie", "150", "2014-01-01")
			UserProfileModel.deleteFood("kevin", ["chicken pot pie"]).should == UserProfileModel::SUCCESS
			entries = UserProfileModel.getEntries("kevin")
			entries.length.should == 1
		end
	end
	describe "getting today's entries" do
		it "should only retrieve today's entries" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.addFood("kevin", "chicken pot pie", "150", Date.today.to_s)
			UserProfileModel.addFood("kevin", "ice cream", "175", (Date.today-1).to_s)
			entries = UserProfileModel.getEntries("kevin")
			entries.length.should == 2
			todays_entries = UserProfileModel.getEntriesByDate("kevin", Date.today.to_s)
			todays_entries.length.should == 1
			todays_entries[0][0].should == "chicken pot pie"
			todays_entries[0][1].should == "150"
			todays_entries[0][2].should == Date.today.to_s
		end
	end
	describe "getting the workout plan" do
		it "should return the exercise plan" do
			UserProfileModel.signup("kevin", "secret")
			UserProfileModel.addFood("kevin", "chicken pot pie", "1000", Date.today.to_s)
			UserProfileModel.addFood("kevin", "ice cream", "100", (Date.today-1).to_s)
			UserProfileModel.addFood("kevin", "dragon tail", "2000", Date.today.to_s)
			target = UserProfileModel.getTarget("kevin")
			target.should == 2000
			intake = UserProfileModel.getIntake("kevin", Date.today.to_s)
			intake.should == 3000
			UserProfileModel.getRecommended(target, intake).should == 120
		end
    end
end

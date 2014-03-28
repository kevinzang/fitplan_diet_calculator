require 'spec_helper'
require File.expand_path("../../../app/models/user_profile", __FILE__)
require File.expand_path("../../../app/models/food_search", __FILE__)
require File.expand_path("../../../app/models/food_entry", __FILE__)
require 'date'

describe "Fitplan Unit Tests" do
	before(:each) {
		UserProfile.reset()
	}
	after(:each) {
		UserProfile.reset()
	}
	describe "add new user" do
		it "should not have a blank username" do
			result = UserProfile.signup("", "secret")
			result.should == UserProfile::ERR_BAD_USERNAME
		end
		it "should not have a username that is too long" do
			name = "a"*(UserProfile::MAX_USERNAME_LENGTH+1)
			UserProfile.signup(name, "secret").should == UserProfile::ERR_BAD_USERNAME
		end
		it "can have a blank password" do
			UserProfile.signup("kevin", "").should == UserProfile::SUCCESS
		end
		it "should not have a password that is too long" do
			pass = "a"*(UserProfile::MAX_PASSWORD_LENGTH+1)
			UserProfile.signup("kevin", pass).should == UserProfile::ERR_BAD_PASSWORD
		end
		it "should not add an already registered user" do
			UserProfile.signup("kevin", "secret").should == UserProfile::SUCCESS
			UserProfile.signup("kevin", "secret").should == UserProfile::ERR_USER_EXISTS
		end
	end
	describe "log in returning user" do
		it "should fail if user does not exist" do
			UserProfile.login("kevin", "secret").should == UserProfile::ERR_BAD_CREDENTIALS
		end
		it "should fail if password is incorrect" do
			UserProfile.signup("kevin", "secret")
			UserProfile.login("kevin", "Secret").should == UserProfile::ERR_BAD_CREDENTIALS
		end
		it "should work if username/password combo is correct" do
			UserProfile.signup("kevin", "secret")
			UserProfile.login("kevin", "secret").should == UserProfile::SUCCESS
		end
	end
	describe "submit profile form" do
		before(:each) {
			UserProfile.signup("kevin", "secret")
		}
		it "should fail if fields contain negative values" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155", "desired_weight"=>"150", "age"=>"-20"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should fail if fields contain words" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155", "desired_weight"=>"150", "age"=>"twenty"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should work if all fields are either blank or non-negative integers" do
			fields = {"feet"=>"5", "inches"=>"0", "weight"=>"155", "desired_weight"=>"150", "age"=>"20"}
			UserProfile.setProfile("kevin", fields.keys, fields).should == UserProfile::SUCCESS
		end
	end
	describe "search for food to add" do
		it "should return the search results" do
			results = FoodSearch.search("mashed potatoes")
			results.length.should > 0
			results[0].should == "Potatoes, Mashed, Home-prepared, Whole Milk And Margarine Added"
		end
		it "should return 'No Results Found' if no search results are found" do
			results = FoodSearch.search("ore no imouto ga konnani kawaii wake ga nai")
			results.length.should > 0
			results[0].should == "No Results Found"
		end
    end
    describe "get calorie for food" do
		it "should return the calorie" do
			results = FoodSearch.search("mashed potatoes")
			results.length.should > 5
			results[5].should == "Potatoes, Mashed, Dehydrated, Prepared From Flakes "+
			"- Without Milk, Whole Milk And Butter Add"
			entry = FoodSearch.getCalorie(5)
			entry.calories.should == "204"
			entry.serving.should == "Serving Size 1 cup (210 g)"
			entry.date.should == Date.today.to_s
			entry.searched.should == true
		end
    end
    describe "add food" do
		it "should fail if user is not registered" do
			UserProfile.addFood("kevin", "chicken", "150",
				"2014-01-01", "10 bells", "2").should_not == UserProfile::SUCCESS
		end
		it "should work if user is registered" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken", "150", "2014-01-01",
				"10 oolongs", "9000").should == UserProfile::SUCCESS
			entries = UserProfile.getEntries("kevin")
			entries.length.should == 1
			entries[0].food.should == "chicken"
			entries[0].calories.should == 150
			entries[0].date.should == "2014-01-01"
			entries[0].serving.should == "10 oolongs"
			entries[0].numservings.should == 9000
		end
		it "should not allow num servings to be non-numeric or non-positive" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken", "150", "2014-01-01",
				"10 oolongs", "moonwalk").should_not == UserProfile::SUCCESS
			UserProfile.addFood("kevin", "chicken", "150", "2014-01-01",
				"10 oolongs", "0").should_not == UserProfile::SUCCESS
		end
	end
	describe "delete food" do
		it "should fail if user is not registered" do
			UserProfile.deleteFood("kevin", ["chicken"]).should_not == UserProfile::SUCCESS
		end
		it "should not have any effect if food not in list" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken", "150",
				"2014-01-01", "10 bells", "2")
			UserProfile.deleteFood("kevin", ["beans"]).should == UserProfile::SUCCESS
			entries = UserProfile.getEntries("kevin")
			entries.length.should == 1
			entries[0].food.should == "chicken"
			entries[0].calories.should == 150
			entries[0].date.should == "2014-01-01"
		end
		it "should delete entries one at a time" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken pot pie", "150",
				"2014-01-01", "10 bells", "2")
			UserProfile.addFood("kevin", "chicken pot pie", "150",
				"2014-01-01", "10 bells", "2")
			UserProfile.deleteFood("kevin", ["chicken pot pie"]).should == UserProfile::SUCCESS
			entries = UserProfile.getEntries("kevin")
			entries.length.should == 1
		end
	end
	describe "getting today's entries" do
		it "should only retrieve today's entries" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken pot pie", "150",
				Date.today.to_s, "10 bells", "2")
			UserProfile.addFood("kevin", "ice cream", "175",
				(Date.today-1).to_s, "10 bells", "2")
			entries = UserProfile.getEntries("kevin")
			entries.length.should == 2
			todays_entries = UserProfile.getEntriesByDate("kevin", Date.today.to_s)
			todays_entries.length.should == 1
			todays_entries[0].food.should == "chicken pot pie"
			todays_entries[0].calories.should == 150
			todays_entries[0].date.should == Date.today.to_s
		end
	end
	describe "getting the workout plan" do
		it "should return the exercise plan" do
			UserProfile.signup("kevin", "secret")
			UserProfile.addFood("kevin", "chicken pot pie", "1000",
				Date.today.to_s, "10 bells", "2")
			UserProfile.addFood("kevin", "ice cream", "100",
				(Date.today-1).to_s, "10 bells", "2")
			UserProfile.addFood("kevin", "dragon tail", "2000",
				Date.today.to_s, "10 bells", "2")
			target = UserProfile.getTarget("kevin")
			target.should == 2000
			intake = UserProfile.getIntake("kevin", Date.today.to_s)
			intake.should == 3000
			UserProfile.getRecommended(target, intake).should == 120
		end
    end
end

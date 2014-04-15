require 'spec_helper'
require File.expand_path("../../../app/models/user_profile", __FILE__)
require File.expand_path("../../../app/models/food_search", __FILE__)
require File.expand_path("../../../app/models/food_entry", __FILE__)
require File.expand_path("../../../app/models/workout_entry", __FILE__)
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
			result = UserProfile.signup("", "secret", "0")
			result.should == UserProfile::ERR_BAD_USERNAME
		end
		it "should not have a username that is too long" do
			name = "a"*(UserProfile::MAX_USERNAME_LENGTH+1)
			UserProfile.signup(name, "secret", "0").should == UserProfile::ERR_BAD_USERNAME
		end
		it "can have a blank password" do
			UserProfile.signup("kevin", "", "0").should == UserProfile::SUCCESS
		end
		it "should not have a password that is too long" do
			pass = "a"*(UserProfile::MAX_PASSWORD_LENGTH+1)
			UserProfile.signup("kevin", pass, "0").should == UserProfile::ERR_BAD_PASSWORD
		end
		it "should not add an already registered user" do
			UserProfile.signup("kevin", "secret", "0").should == UserProfile::SUCCESS
			UserProfile.signup("kevin", "secret", "0").should == UserProfile::ERR_USER_EXISTS
		end
	end
	describe "log in returning user" do
		it "should fail if user does not exist" do
			UserProfile.login("kevin", "secret", "0").should == UserProfile::ERR_BAD_CREDENTIALS
		end
		it "should fail if password is incorrect" do
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.login("kevin", "Secret", "0").should == UserProfile::ERR_BAD_CREDENTIALS
		end
		it "should work if username/password combo is correct" do
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.login("kevin", "secret", "0").should == UserProfile::SUCCESS
		end
	end
	describe "submit profile form" do
		before(:each) {
			UserProfile.signup("kevin", "secret", "0")
		}
		it "should fail if fields contain negative values" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"-20", "gender"=>"female"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should fail if fields contain words" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"twenty", "gender"=>"female"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should work if all fields are either blank or non-negative integers" do
			fields = {"feet"=>"5", "inches"=>"0", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"20", "gender"=>"male"}
			UserProfile.setProfile("kevin", fields.keys, fields).should == UserProfile::SUCCESS
		end
	end
	describe "set profile form preexisting values" do
		before(:each) {
			UserProfile.signup("kevin", "secret", "0")
		}
		it "should initially have empty strings for defaults" do
			defaults = UserProfile.getDefaults("kevin")
			for value in defaults.values
				value.should == ""
			end
		end
		it "should remember the defaults" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"20", "gender"=>"male"}
			UserProfile.setProfile("kevin", fields.keys, fields).should == UserProfile::SUCCESS
			defaults = UserProfile.getDefaults("kevin")
			for key in defaults.keys
				defaults[key].should == fields[key]
			end
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
			UserProfile.signup("kevin", "secret", "0")
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
			UserProfile.signup("kevin", "secret", "0")
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
			UserProfile.signup("kevin", "secret", "0")
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
			UserProfile.signup("kevin", "secret", "0")
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
			UserProfile.signup("kevin", "secret", "0")
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
		it "should report the intake" do
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.addFood("kevin", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			workout = UserProfile.getWorkout("kevin", Date.today.to_s)
			workout["intake"].should == 2660 # 266 * 10
			workout["burned"].should == 0 # no WorkoutEntries entered
			workout["target"].should == -1 # profile form not set
			workout["normal"].should == -1 # profile form not set
		end
		it "should report the target and normal for completed profile form" do
			UserProfile.signup("kevin", "secret", "0")
			fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male"}
			UserProfile.setProfile("kevin", fields.keys, fields)
			UserProfile.addFood("kevin", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			workout = UserProfile.getWorkout("kevin", Date.today.to_s)
			workout["intake"].should == 2660 # 266 * 10
			workout["burned"].should == 0 # no WorkoutEntries entered
			workout["target"].should == 1760 # BMR desired weight
			workout["normal"].should == 1800 # BMR weight
		end
		it "should use a default of -1 for rec_target and rec_normal" do
			UserProfile.signup("kevin", "secret", "0")
			rec = UserProfile.getRecommended("kevin", 0, 0, "")
			rec["rec_target"].should == -1
			rec["rec_normal"].should == -1
		end
		it "should figure out rec_target and rec_normal" do
			UserProfile.signup("kevin", "secret", "0")
			fields = {"feet"=>"", "inches"=>"", "weight"=>"165",
				"desired_weight"=>"", "age"=>"", "gender"=>""}
			UserProfile.setProfile("kevin", fields.keys, fields)
			rec = UserProfile.getRecommended("kevin", 2000, 1500,
				"Running, 6 mph (10 min mile)")
			rec["rec_target"].should == 160 # target: need to burn 2000
			rec["rec_normal"].should == 120 # normal: need to burn 1500
		end
  end
  describe "getting workout activities" do
  	it "should retrieve activities" do
  		activities = WorkoutEntry.getActivities
  		activities.include?("Aerobics, general").should == true
			activities.include?("Ballet, twist, jazz, tap").should == true
			activities.include?("Canoeing, camping trip").should == true
  	end
  	it "should look up rates for activities" do
  		WorkoutEntry.getRate("Aerobics, general").should == 2.95
			WorkoutEntry.getRate("Ballet, twist, jazz, tap").should == 2.04
			WorkoutEntry.getRate("Canoeing, camping trip").should == 1.81
  	end
  end
  describe "adding workout entries" do
  	it "should return error for nonexistant user" do
  		result = UserProfile.addWorkoutEntry("phantom",
  			"Running, 6 mph (10 min mile)", "30", Date.today.to_s)
  		result.should == UserProfile::ERR_USER_NOT_FOUND
  	end
  	it "should return error for nonexistant activity" do
  		UserProfile.signup("a", "secret", "0")
  		result = UserProfile.addWorkoutEntry("a",
  			"underwater basket weaving", "30", Date.today.to_s)
  		result.should == UserProfile::ERR_ACTIVITY_NOT_FOUND
  	end
  	it "should return error if user has no weight" do
  		UserProfile.signup("a", "secret", "0")
  		result = UserProfile.addWorkoutEntry("a",
  			"Running, 6 mph (10 min mile)", "30", Date.today.to_s)
  		result.class.should == String
  	end
  	it "should add entry for valid entry" do
  		UserProfile.signup("a", "secret", "0")
  		fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
			"desired_weight"=>"155", "age"=>"20", "gender"=>"male"}
		UserProfile.setProfile("a", fields.keys, fields)
  		result = UserProfile.addWorkoutEntry("a",
  			"Running, 6 mph (10 min mile)", "30", Date.today.to_s)
  		result.should == 363
  		result = UserProfile.addWorkoutEntry("a",
  			"Running, 6 mph (10 min mile)", "30", Date.today.to_s)
  		result.should == 726
  	end
  end
  describe "user authentication" do
  	it "should set the remember token" do
  		UserProfile.signup("kevin", "secret", "0")
  		username = UserProfile.getUsername("0")
  		username.should == "kevin"
  	end
  	it "should sign out" do
  		UserProfile.signup("kevin", "secret", "0")
  		UserProfile.signout("0")
  		user = UserProfile.find_by(username:"kevin")
  		user.remember_token.should == nil
  	end
  end
  describe "getting calorie intake chart data" do
    it "should return nil if user does not exist" do
      UserProfile.calorieIntakeChartData("derp", 12).should == nil
    end
    it "should return {} if range_in_months < 0" do
      UserProfile.signup("kevin", "secret", "0")
      UserProfile.addFood("kevin", "ice cream", "1000", Date.today.to_s, "serving", "1")
      UserProfile.addFood("kevin", "french fries", "700", Date.today.to_s, "serving", "1")
      UserProfile.addFood("kevin", "ice cream", "1000", Date.today.to_s, "serving", "1")
      chartData = UserProfile.calorieIntakeChartData("kevin", -1)
      chartData.should == {}
    end
    it "should set range_in_months to 12 if range_in_months > 12" do
      UserProfile.signup("kevin", "secret", "0")
      UserProfile.addFood("kevin", "french fries", "700", (Date.today - 11.months).to_s, "serving", "1")
      UserProfile.addFood("kevin", "pho", "700", (Date.today - 19.months).to_s, "serving", "1")
      chartData = UserProfile.calorieIntakeChartData("kevin", 20)
      chartData.has_key?((Date.today - 11.months).to_s).should == true
      chartData[(Date.today - 11.months).to_s].should == 700
      chartData.has_key?((Date.today - 19.months).to_s).should == false
    end
    it "should combine foods in the same day" do
      UserProfile.signup("kevin", "secret", "0")
      UserProfile.addFood("kevin", "ice cream", "1000", Date.today.to_s, "serving", "1")
      UserProfile.addFood("kevin", "french fries", "700", Date.today.to_s, "serving", "1")
      UserProfile.addFood("kevin", "ice cream", "1000", Date.today.to_s, "serving", "1")
      chartData = UserProfile.calorieIntakeChartData("kevin", 12)
      chartData[Date.today.to_s].should == 2700
    end
    it "should multiply calories by number of servings" do
      UserProfile.signup("kevin", "secret", "0")
      UserProfile.addFood("kevin", "ice cream", "1000", Date.today.to_s, "serving", "7")
      chartData = UserProfile.calorieIntakeChartData("kevin", 12)
      chartData[Date.today.to_s].should == 7000
    end
    it "should ignore entries outside of search range" do
      UserProfile.signup("kevin", "secret", "0")
      UserProfile.addFood("kevin", "ice cream", "1000", (Date.today - 4.months).to_s, "serving", "7")
      chartData = UserProfile.calorieIntakeChartData("kevin", 3)
      chartData.has_key?(Date.today - 4.months).should == false
      chartData = UserProfile.calorieIntakeChartData("kevin", 5)
      chartData.has_key?((Date.today - 4.months).to_s).should == true
    end
  end
end
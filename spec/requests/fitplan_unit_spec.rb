require 'spec_helper'
require 'open-uri'

describe "Fitplan Unit Tests" do
	puts "***begin fitplan_unit_spec.rb"
	before(:each) {
		UserProfile.reset()
		WeightEntry.delete_all()
	}
	after(:each) {
		UserProfile.reset()
		WeightEntry.delete_all()
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
				"desired_weight"=>"150", "age"=>"-20", "gender"=>"female",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should fail if fields contain words" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"twenty", "gender"=>"female",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
			UserProfile.setProfile("kevin", fields.keys, fields).should_not == UserProfile::SUCCESS
		end
		it "should work if all fields are either blank or non-negative integers" do
			fields = {"feet"=>"5", "inches"=>"0", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"20", "gender"=>"male",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
			UserProfile.setProfile("kevin", fields.keys, fields).should == UserProfile::SUCCESS
		end
	end
	describe "set profile form preexisting values" do
		before(:each) {
			UserProfile.signup("kevin", "secret", "0")
		}
		it "should initially have empty strings for defaults" do
			defaults = UserProfile.getDefaults("kevin")
			for key in defaults.keys
				if key == "activity_level"
					defaults[key].should == "0"
				elsif key == "weight_change_per_week_goal"
					defaults[key].should == "0.0"
				else
					defaults[key].should == ""
				end
			end
		end
		it "should remember the defaults" do
			fields = {"feet"=>"5", "inches"=>"7", "weight"=>"155",
				"desired_weight"=>"150", "age"=>"20", "gender"=>"male",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
			UserProfile.deleteFood("kevin", ["chicken"], 0).should_not == UserProfile::SUCCESS
		end
		it "should not have any effect if food not in list" do
			today = Date.today
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.addFood("kevin", "chicken", "150",
				today.to_s, "10 bells", "2")
			UserProfile.deleteFood("kevin", ["beans"], today.to_s).should == UserProfile::SUCCESS
			entries = UserProfile.getEntries("kevin")
			entries.length.should == 1
			entries[0].food.should == "chicken"
			entries[0].calories.should == 150
			entries[0].date.should == today.to_s
		end
		it "should delete entries one at a time" do
			UserProfile.signup("kevin", "secret", "0")
			today = Date.today
			UserProfile.addFood("kevin", "chicken pot pie", "150",
				today.to_s, "10 bells", "2")
			UserProfile.addFood("kevin", "chicken pot pie", "150",
				today.to_s, "10 bells", "2")
			UserProfile.deleteFood("kevin", ["chicken pot pie"], today.to_s).should == UserProfile::SUCCESS
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
	describe "getting the Profile gauge level" do
		it "should increment for each consecutive day" do
			UserProfile.signup("kevin", "secret", "0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.last_login.should == Date.today.to_s
			kevin.gauge_level.should == 0
			UserProfile.signout("0")
			for _ in 1..10
				kevin = UserProfile.find_by(username:"kevin")
				kevin.last_login = (Date.today-1).to_s
				kevin.save()
				UserProfile.login("kevin", "secret", "0")
				UserProfile.signout("0")
			end
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level.should == 10
			kevin.last_login.should == Date.today.to_s
		end
		it "should not increment past 30" do
			UserProfile.signup("kevin", "secret", "0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.last_login.should == Date.today.to_s
			kevin.gauge_level.should == 0
			UserProfile.signout("0")
			for _ in 1..31
				kevin = UserProfile.find_by(username:"kevin")
				kevin.last_login = (Date.today-1).to_s
				kevin.save()
				UserProfile.login("kevin", "secret", "0")
				UserProfile.signout("0")
			end
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level.should == 30
			kevin.last_login.should == Date.today.to_s
		end
		it "should decrement by 2 for every skipped day" do
			UserProfile.signup("kevin", "secret", "0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level = 30
			kevin.last_login = (Date.today-3).to_s
			kevin.save()
			UserProfile.signout("0")
			UserProfile.login("kevin", "secret", "0")
			UserProfile.signout("0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level.should == 26
			kevin.last_login.should == Date.today.to_s
		end
		it "should not decrement past 0" do
			UserProfile.signup("kevin", "secret", "0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level = 2
			kevin.last_login = (Date.today-3).to_s
			kevin.save()
			UserProfile.signout("0")
			UserProfile.login("kevin", "secret", "0")
			UserProfile.signout("0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level.should == 0
			kevin.last_login.should == Date.today.to_s
		end
		it "should not do anything if user logs in twice on same day" do
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.signout("0")
			UserProfile.login("kevin", "secret", "0")
			UserProfile.signout("0")
			UserProfile.login("kevin", "secret", "0")
			UserProfile.signout("0")
			kevin = UserProfile.find_by(username:"kevin")
			kevin.gauge_level.should == 0
			kevin.last_login.should == Date.today.to_s
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
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
			UserProfile.setProfile("kevin", fields.keys, fields)
			UserProfile.addFood("kevin", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			workout = UserProfile.getWorkout("kevin", Date.today.to_s)
			workout["intake"].should == 2660 # 266 * 10
			workout["burned"].should == 0 # no WorkoutEntries entered
			workout["target"].should == 1975 # <strike>BMR desired weight</strike> Recommended Calorie Intake to Maintain Weight
			workout["normal"].should == 2475 # <strike>BMR weight</strike> Recommended Calorie Intake to lose <weight_change_per_week_goal> pounds per week
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
				"desired_weight"=>"", "age"=>"", "gender"=>"",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
			"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
			"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
	describe "UserProfile.addWeightEntry(...)" do
		before(:each) {
			UserProfile.reset()
			WeightEntry.delete_all()
		}
		it "should error for invalid user" do
			result = UserProfile.addWeightEntry("kevin", "1", Date.today.to_s)
			result.should == "Error: user not found"
		end
		it "should error for weight < 0" do
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addWeightEntry("kevin", "-1", Date.today.to_s)
			result.should == "Error: weight must be positive"
			WeightEntry.find_by(username: "kevin").should == nil
		end
		it "should error for weight > 1000" do
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addWeightEntry("kevin", "1001", Date.today.to_s)
			result.should == "Error: weight must be <= 1000"
			WeightEntry.find_by(username: "kevin").should == nil
		end
		it "should succeed if weight and user are valid" do
			date = Date.today
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addWeightEntry("kevin", "211", date.to_s)
			result.should == "SUCCESS"
			entry = WeightEntry.find_by(username: "kevin")
			entry.should_not == nil
			entry.username.should == "kevin"
			entry.weight.should == 211
			entry.date.should == date.to_s
		end
	end
	describe "UserProfile.getWeightEntries(...)" do
		it "should return all weight entries, lowest weight for each day" do
			date = Date.today
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.addWeightEntry("kevin", "211", date.to_s)
			UserProfile.addWeightEntry("kevin", "210", date.to_s)
			UserProfile.addWeightEntry("kevin", "209", (date + 1.days).to_s)
			entries = UserProfile.getWeightEntries("kevin")
			entries.length.should == 2
			entries[0].weight.should == 210
			entries[1].weight.should == 209
		end
	end
	describe "UserProfile.getWeightEntriesInRange(...)" do
		it "should return only weight entries in range" do
			current_date = Date.today
			out_of_range_date = current_date - 5.months
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.addWeightEntry("kevin", "211", (current_date - 5.days).to_s)
			UserProfile.addWeightEntry("kevin", "5", out_of_range_date.to_s)
			entries = UserProfile.getWeightEntriesInRange("kevin", 3)
			entries.length.should == 1
			entries[0].weight.should == 211
		end
	end
	describe "UserProfile.weightChartData(...)" do
		it "should return all weight entries in range, in format requested by chartkick gem" do
			date = Date.today
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.addWeightEntry("kevin", "211", date.to_s)
			UserProfile.addWeightEntry("kevin", "212", (date - 3.days).to_s)
			UserProfile.addWeightEntry("kevin", "216", (date - 10.days).to_s)
			UserProfile.addWeightEntry("kevin", "999", (date - 5.months).to_s)
			chartData = UserProfile.weightChartData("kevin", 3)
			chartData.size.should == 3
			chartData[date.to_s].should == 211
			chartData[(date - 3.days).to_s].should == 212
			chartData[(date - 10.days).to_s].should == 216
			chartData[(date - 5.months).to_s].should == nil
		end
	end
	describe "UserProfile.recommendedCalorieIntake(...)" do
		it "should return the correct number of calories" do
			UserProfile.signup("kevin", "secret", "0")
			user = UserProfile.find_by(username: "kevin")
			for height in 66..67
				for weight in 130..131
					for age in 23..24
						for gender in ["male", "female"]
							for activity_level in [0, 1, 2, 3, 4]
								for weight_change_per_week_goal in [0.0, 0.5, 1.0, 1.5, 2.0]
									# expected
									bmr = nil
									if gender == "male"
										bmr = (65 + 13.8*weight/2.2 + 5*height*2.54 - 6.8*age).round(-1)
									else # gender == "female"
										bmr = (655 + 9.6*weight/2.2 + 1.8*height*2.54 - 4.7*age).round(-1)
									end
									scale_factor = 1.2 + 0.175 * activity_level
									calorie_change_per_week = 3500 * weight_change_per_week_goal
									calorie_change_per_day = calorie_change_per_week / 7
									expected = scale_factor * bmr + calorie_change_per_day
									# actual
									user.height = height
									user.weight = weight
									user.age = age
									user.gender = gender
									user.activity_level = activity_level
									user.weight_change_per_week_goal = weight_change_per_week_goal
									user.save()
									actual = UserProfile.recommendedCalorieIntake("kevin")
									actual.should == expected
								end
							end
						end
					end
				end
			end
		end
	end
	describe "UserProfile.addUserFood(...)" do
		it "should return ERR_USER_NOT_FOUND if user doesn't exist" do
			result = UserProfile.addUserFood("derp", "derp", "derp", "derp")
			result.should == UserProfile::ERR_USER_NOT_FOUND
		end
		it "should not add foods with nonpositive calories" do
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addUserFood("kevin", "ice cream yum", "0", "serving")
			result.should == "Calories must be positive"
		end
		it "should not add foods with nonnumeric calories" do
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addUserFood("kevin", "ice cream yum", "derp", "serving")
			result.should == "Calories must be an integer"
		end
		it "should add user food if no errors" do
			UserProfile.signup("kevin", "secret", "0")
			result = UserProfile.addUserFood("kevin", "ice cream yum", "120", "serving")
			result.should == UserProfile::SUCCESS
			entries = UserProfile.getUserFoods("kevin", "")
			entries.length.should == 1
			entries[0].username.should == "kevin"
			entries[0].food.should == "ice cream yum"
			entries[0].calories.should == 120
			entries[0].serving.should == "serving"
		end
		it "should overwrite preexisting user foods with same username, food, serving" do
			UserProfile.signup("kevin", "secret", "0")
			UserProfile.signup("not kevin", "secret", "1")
			UserProfile.addUserFood("kevin", "ice cream yum", "120", "serving")
			UserProfile.addUserFood("kevin", "ice cream", "121", "serving")
			UserProfile.addUserFood("kevin", "ice cream yum", "122", "serving 2")
			UserProfile.addUserFood("kevin", "ice cream yum", "123", "serving")
			UserProfile.addUserFood("not kevin", "ice cream yum", "124", "serving")
			entries = UserProfile.getUserFoods("kevin", "").sort!{|a, b| a.calories <=> b.calories}
			entries.length.should == 3
			entries[0].username.should == "kevin"
			entries[0].food.should == "ice cream"
			entries[0].calories.should == 121
			entries[0].serving.should == "serving"
			entries[1].username.should == "kevin"
			entries[1].food.should == "ice cream yum"
			entries[1].calories.should == 122
			entries[1].serving.should == "serving 2"
			entries[2].username.should == "kevin"
			entries[2].food.should == "ice cream yum"
			entries[2].calories.should == 123
			entries[2].serving.should == "serving"
		end
  end
  describe "UserProfile.weightChartDataFriends(...)" do
    it "should return valid chart data" do
      UserProfile.signup("kevin0", "", "0")
      UserProfile.signup("kevin1", "", "0")
      UserProfile.signup("kevin2", "", "0")
      UserProfile.signup("kevin3", "", "0")
      Friendship.delete_all()
      Friendship.create(:usernameFrom => "kevin0", :usernameTo => "kevin1")
      Friendship.create(:usernameFrom => "kevin1", :usernameTo => "kevin0")
      Friendship.create(:usernameFrom => "kevin0", :usernameTo => "kevin3")
      Friendship.create(:usernameFrom => "kevin3", :usernameTo => "kevin0")
      UserProfile.addWeightEntry("kevin0", "210", Date.today.to_s)
      UserProfile.addWeightEntry("kevin0", "211", (Date.today - 1).to_s)
      UserProfile.addWeightEntry("kevin1", "156", Date.today.to_s)
      UserProfile.addWeightEntry("kevin2", "9000", Date.today.to_s)
      UserProfile.addWeightEntry("kevin3", "500", Date.today.to_s)
      UserProfile.addWeightEntry("kevin3", "505", (Date.today - 2).to_s)
      chart_data = UserProfile.weightChartDataFriends("kevin0", 3)
      expected = [{"name" => "kevin0", "data" => {Date.today.to_s => 210, (Date.today - 1).to_s => 211}},
                  {"name" => "kevin1", "data" => {Date.today.to_s => 156}},
                  {"name" => "kevin3", "data" => {Date.today.to_s => 500, (Date.today - 2).to_s => 505}}]
      chart_data.size.should == expected.size
      chart_data.include?(expected[0]).should == true
      chart_data.include?(expected[1]).should == true
      chart_data.include?(expected[2]).should == true
    end
  end
  describe "UserProfile.setPic(...)" do
    it "should error if file is not jpg or png" do
      UserProfile.signup("kevin", "secret", "0")
      data = File.open(Dir.pwd + '/spec/requests/files/wrong_content_type.ppt')
      result = UserProfile.setPic("kevin", data)
      result.should == "ERROR: Invalid file format. jpg or png only."
    end
    it "should error if file is > 5 MB" do
      UserProfile.signup("kevin", "secret", "0")
      data = File.open(Dir.pwd + '/spec/requests/files/too_large.jpg')
      result = UserProfile.setPic("kevin", data)
      result.should == "ERROR: Maximum file size is 5 MB"
    end
    it "should error if file not uploaded" do
      UserProfile.signup("kevin", "secret", "0")
      result = UserProfile.setPic("kevin", nil)
      result.should == "ERROR: Must upload a file"
    end
    it "should set pic to uploaded file" do
      UserProfile.signup("kevin", "secret", "0")
      data = File.open(Dir.pwd + '/spec/requests/files/pikachu.jpg')
      result = UserProfile.setPic("kevin", data)
      result.should == "SUCCESS"
      user = UserProfile.find_by(:username => "kevin")
      user.profile_pic.should_not == nil
      #aws_data = open(user.profile_pic.url)
      #aws_data.nil?.should == false
    end
  end
	puts "***end fitplan_unit_spec.rb"
end

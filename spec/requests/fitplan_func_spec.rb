require 'spec_helper'
require File.expand_path("../../../app/models/user_profile", __FILE__)
require File.expand_path("../../../app/models/food_search", __FILE__)
require 'date'
require 'json'

describe "Fitplan Functional Tests" do
	before(:each) {
		UserProfile.reset()
	}
	after(:each) {
		UserProfile.reset()
	}
	session = {'CONTENT_TYPE'=>'application/json',
		'ACCEPT' => 'application/json'}
	describe "add new user" do
		it "should add new user" do
			UserProfile.isRegistered?("kevin").should == false
			req = {"username"=>"kevin", "password"=>"secret"}
			resp = {"result"=>UserProfile::SUCCESS}
			post '/signup_submit', req.to_json, session
			response.body.should == resp.to_json
			UserProfile.isRegistered?("kevin").should == true
		end
	end
	describe "log in returning user" do
		it "should log in user" do
			UserProfile.signup("kevin", "secret", "0")
			req = {"username"=>"kevin", "password"=>"secret"}
			resp = {"result"=>UserProfile::SUCCESS}
			post '/login_submit', req.to_json, session
			response.body.should == resp.to_json
		end
	end
	describe "submit profile form" do
		it "should submit profile" do
			cookies[:remember_token] = "0"
			UserProfile.signup("dragon", "secret", "0")
			req = {"feet"=>"5", "inches"=>"0", "weight"=>"150",
				"desired_weight"=>"140", "age"=>"20", "gender"=>"male",
        "activity_level"=>"0", "weight_change_per_week_goal"=>"0.0"}
			resp = {"result"=>UserProfile::SUCCESS}
			post '/profile_form/submit', req.to_json, session
			response.body.should == resp.to_json
			record = UserProfile.find_by(username:"dragon")
			record.height.should == 60
			record.weight.should == 150
			record.desired_weight.should == 140
			record.age.should == 20
			record.gender.should == "male"
		end
	end
	describe "set profile form preexisting values" do
		it "should remember the defaults" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			req = {"feet"=>"5", "inches"=>"0", "weight"=>"150",
				"desired_weight"=>"140", "age"=>"20", "gender"=>"male",
        "activity_level"=>"0", "weight_change_per_week_goal"=>"0.0"}
			UserProfile.setProfile("a", req.keys, req).should == UserProfile::SUCCESS
			get '/profile_form'
			defaults = assigns(:defaults)
			for key in defaults
				defaults[key].should == req[key]
			end
		end
	end
	describe "search for food to add" do
		it "should set @food and @results" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			post '/profile/add_food', {'food' => "mashed potatoes"}
			assigns(:food).should == "mashed potatoes"
			assigns(:results).length.should > 0
			assigns(:results)[0].should ==
			"Potatoes, Mashed, Home-prepared, Whole Milk And Margarine Added"
		end
    end
    describe "get calorie for food" do
		it "should return the calorie" do
			FoodSearch.search("mashed potatoes")
			req = {"num"=>"5"}
			resp = {"calorie"=>"204", "serving"=>"Serving Size 1 cup (210 g)"}
			post '/profile/add_food/get_calorie', req.to_json, session
			response.body.should == resp.to_json
		end
    end
    describe "add food" do
		it "should add the food entry" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			entries = UserProfile.getEntries("a")
			entries.length.should == 0
			FoodSearch.search("mashed potatoes")
			FoodSearch.getCalorie(5)
			req = {"num" => "5", "num_servings" => "2"}
			resp = {"result" => UserProfile::SUCCESS}
			post '/profile/add_food/get_calorie/add', req.to_json, session
			entries = UserProfile.getEntries("a")
			entries.length.should == 1
			entries[0].food.should == "Potatoes, Mashed, Dehydrated, Prepared From Flakes "+
			"- Without Milk, Whole Milk And Butter Add"
			entries[0].calories.should == 204
			entries[0].date.should == Date.today.to_s
			entries[0].serving.should == "Serving Size 1 cup (210 g)"
			entries[0].numservings.should == 2
		end
	end
	describe "delete food" do
		it "should delete the entries" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			UserProfile.addFood("a", "chicken pot pie", "150",
				"2014-01-01", "10 bells", "2")
			UserProfile.addFood("a", "chicken pot pie", "150",
				"2014-01-01", "10 bells", "2")
			entries = UserProfile.getEntries("a")
			entries.length.should == 2
			req = {"delete" => ["chicken pot pie"].to_s}
			resp = {"result" => UserProfile::SUCCESS}
			post '/profile/delete_food', req.to_json, session
			entries = UserProfile.getEntries("a")
			entries.length.should == 1
		end
	end
	describe "getting today's entries" do
		@today = Date.today.to_s
		@entries = UserProfile.getEntriesByDate("a", @today)
		if @entries.class != Array
			@message = @entries
		else
			@message = "You have #{@entries.length} entries for #{@today}."
		end
		it "should set @today and @entries" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			UserProfile.addFood("a", "chicken pot pie", "150",
				Date.today.to_s, "10 bells", "2")
			UserProfile.addFood("a", "ice cream", "175",
				(Date.today-1).to_s, "10 bells", "2")
			get '/profile'
			assigns(:today).should == Date.today.to_s
			todays_entries = assigns(:entries)
			todays_entries.length.should == 1
			todays_entries[0].food.should == "chicken pot pie"
			todays_entries[0].calories.should == 150
			todays_entries[0].date.should == Date.today.to_s
			todays_entries[0].serving.should == "10 bells"
			todays_entries[0].numservings.should == 2
		end
	end
	describe "getting the workout plan" do
		it "should set @workout" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
        "activity_level"=>"0", "weight_change_per_week_goal"=>"0.0"}
			UserProfile.setProfile("a", fields.keys, fields)
			UserProfile.addFood("a", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			UserProfile.addFood("a", "ice cream", "100",
				(Date.today-1).to_s, "10 bells", "2")
			get '/profile/workout'
			defaultActivity = assigns(:defaultActivity)
			defaultActivity.should == "Running, 6 mph (10 min mile)"
			workout = assigns(:workout)
			workout["target"].should == 1760
			workout["intake"].should == 2660
			workout["normal"].should == 1800
			workout["rec_target"].should == 74
			workout["rec_normal"].should == 71
		end
		it "should set @activities" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			get '/profile/workout'
			activities = assigns(:activities)
			activities.include?("Aerobics, general").should == true
			activities.include?("Ballet, twist, jazz, tap").should == true
			activities.include?("Canoeing, camping trip").should == true
        end
    end
    describe "getting a recommendation" do
    	it "should get a recommendation" do
    		cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
        "activity_level"=>"0", "weight_change_per_week_goal"=>"0.0"}
			UserProfile.setProfile("a", fields.keys, fields)
			UserProfile.addFood("a", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			get '/profile/workout'
			workout = assigns(:workout)
			# workout["target"].should == 1760
			# workout["intake"].should == 2660
			# workout["normal"].should == 1800
			# workout["rec_target"].should == 74
			# workout["rec_normal"].should == 71
			req = {"activity" => "Bird watching",
				"target_cal" => 1760, "normal_cal" => 1800} # rate=1.14
			resp = {"rec_target" => 579, "rec_normal" => 592}
			post '/profile/workout/get_recommended', req.to_json, session
			response.body.should == resp.to_json
		end
	end
    describe "adding workout entries" do
    	it "should add workout entry" do
    		cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
        "activity_level"=>"0", "weight_change_per_week_goal"=>"0.0"}
			UserProfile.setProfile("a", fields.keys, fields)
			UserProfile.addFood("a", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			get '/profile/workout'
			workout = assigns(:workout)
			# original plan
			# workout["target"].should == 1760
			# workout["intake"].should == 2660
			# workout["normal"].should == 1800
			# workout["rec_target"].should == 74
			# workout["rec_normal"].should == 71
			workout["burned"].should == 0

			# add a WorkoutEntry
			req = {"activity" => "Bird watching", # rate=1.14
				"minutes" => "30"}
			resp = {"result" => UserProfile::SUCCESS, "burned" => 91}
			post '/profile/workout/add_entry', req.to_json, session
			response.body.should == resp.to_json

			# check that new plan accounts for new WorkoutEntry
			get '/profile/workout'
			workout = assigns(:workout)
			workout["target"].should == 1760
			workout["intake"].should == 2660
			workout["normal"].should == 1800
			workout["rec_target"].should == 67
			workout["rec_normal"].should == 64
			workout["burned"].should == 91
		end
	end
    describe "user authentication" do
    	it "should remember the user" do
    		cookies[:remember_token] = "blastoise"
    		UserProfile.signup("squirtle", "wartortle", "blastoise")
    		get '/profile'
    		assigns(:user).should == "squirtle"
    	end
    	it "should sign the user out" do
    		cookies[:remember_token] = "blastoise"
    		UserProfile.signup("squirtle", "wartortle", "blastoise")
    		req = {}
			resp = {"result"=>UserProfile::SUCCESS}
			post '/signout_submit', req.to_json, session
			response.body.should == resp.to_json
    		get '/profile'
    		assigns(:user).should == nil
    	end
    end
  describe "getting calorie intake chart data" do
    it "should set @calorieIntakeChartData" do
      UserProfile.signup("a", "secret", "0")
      start_date = Date.today
      (0..20).each do |offset|
        key = (start_date - offset.days).to_s
        UserProfile.addFood("a", "cereal", "156", key, "serving", "2")
        UserProfile.addFood("a", "salad", "483", key, "serving", "1")
        UserProfile.addFood("a", "snack", "92", key, "serving", "3")
        UserProfile.addFood("a", "pho", "855", key, "serving", "1")
      end
      get '/progress'
      chartData = assigns(:calorieIntakeChartData)
      (0..20).each do |offset|
        key = (start_date - offset.days).to_s
        chartData.has_key?(key).should == true
        chartData[key].should == 2 * 156 + 483 + 3 * 92 + 855
      end
    end
  end
end

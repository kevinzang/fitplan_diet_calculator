require 'spec_helper'

describe "Fitplan Functional Tests" do
	puts "***begin fitplan_func_spec.rb"
	before(:each) {
		UserProfile.reset()
		WeightEntry.delete_all()
	}
	after(:each) {
		UserProfile.reset()
		WeightEntry.delete_all()
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
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
			today = "2014-04-19"
			url_today = today.gsub("-", "_")
			post "/profile/add_food/#{url_today}", {'food' => "mashed potatoes"}
			assigns(:food).should == "mashed potatoes"
			assigns(:day).should == today
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
			post '/profile/get_calorie', req.to_json, session
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
			req = {"num" => "5", "num_servings" => "2", "date" => "04-19-2014"}
			resp = {"result" => UserProfile::SUCCESS}
			post '/profile/get_calorie/add', req.to_json, session
			entries = UserProfile.getEntriesByDate("a", "04-19-2014")
			entries.length.should == 1
			entries[0].food.should == "Potatoes, Mashed, Dehydrated, Prepared From Flakes "+
				"- Without Milk, Whole Milk And Butter Add"
			entries[0].calories.should == 204
			entries[0].date.should == "04-19-2014"
			entries[0].serving.should == "Serving Size 1 cup (210 g)"
			entries[0].numservings.should == 2
		end
	end
	describe "delete food" do
		it "should delete the entries" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			UserProfile.addFood("a", "chicken pot pie", "150",
				"2014-04-19", "10 bells", "2")
			UserProfile.addFood("a", "chicken pot pie", "150",
				"2014-04-19", "10 bells", "2")
			entries = UserProfile.getEntries("a")
			entries.length.should == 2
			req = {"delete" => ["chicken pot pie"].to_s, "date" => "2014-04-19"}
			resp = {"result" => UserProfile::SUCCESS}
			post '/profile/delete_food', req.to_json, session
			entries = UserProfile.getEntriesByDate("a", "2014-04-19")
			entries.length.should == 1
		end
	end
	describe "getting the week's entries" do
		it "should get the week's entries" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			curr = Date.today
			count = curr.wday
			week = []
			while (curr.wday > 0)
				week.push(curr.to_s)
				curr = curr - 1
			end
			week.push(curr.to_s)
			calorie = 1
			for day in week
				for i in 0..2
					UserProfile.addFood("a", "food name", calorie.to_s,
						day, "serving desc.", "1")
					calorie += 1
				end
			end
			get '/profile'
			week_entries = assigns(:entries)
			assigns(:days).should == week
			week_entries.length.should == count + 1
			calorie = 3
			for day in week
				week_entries[day].length.should == 3
				for entry in week_entries[day]
					entry.calories.should <= calorie
					entry.calories.should > calorie - 3
					entry.date.should == day
				end
				calorie += 3
			end
		end
	end
	describe "getting the workout plan" do
		it "should set @workout" do
			cookies[:remember_token] = "0"
			UserProfile.signup("a", "secret", "0")
			fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
				"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
			UserProfile.setProfile("a", fields.keys, fields)
			UserProfile.addFood("a", "chicken", "266",
				Date.today.to_s, "10 bells", "10")
			UserProfile.addFood("a", "ice cream", "100",
				(Date.today-1).to_s, "10 bells", "2")
			get '/profile/workout'
			defaultActivity = assigns(:defaultActivity)
			defaultActivity.should == "Running, 6 mph (10 min mile)"
			workout = assigns(:workout)
			workout["target"].should == 1975
			workout["intake"].should == 2660
			workout["normal"].should == 2475
			workout["rec_target"].should == 57
			workout["rec_normal"].should == 15
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
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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
				"target_cal" => 1800 * 1.2, "normal_cal" => 1800 * 1.2} # rate=1.14
			resp = {"rec_target" => 711, "rec_normal" => 711}
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
				"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
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

			# add a WorkoutEntry. rate=1.14
			req = {"activity" => "Bird watching", "minutes" => "30"}
			resp = {"result" => UserProfile::SUCCESS, "burned" => 91}
			post '/profile/workout/add_entry', req.to_json, session
			response.body.should == resp.to_json

			# check that new plan accounts for new WorkoutEntry
			get '/profile/workout'
			workout = assigns(:workout)
			workout["target"].should == 1975
			workout["intake"].should == 2660
			workout["normal"].should == 2475
			workout["rec_target"].should == 49
			workout["rec_normal"].should == 8
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
			cookies[:remember_token] = "0"
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
	describe "fitplan_controller.add_weight()" do
		it "should successfully add valid weight entry" do
			cookies[:remember_token] = "0"
			UserProfile.signup("kevin", "secret", "0")
			date = Date.today
			req = {"weight" => "117"}
			resp = {"result"=>"success", "message" => "Weight successfully added"}
			post '/profile/add_weight', req.to_json, session
			response.body.should == resp.to_json
			entries = UserProfile.getWeightEntries("kevin")
			entries.length.should == 1
			entry = entries[0]
			entry.should_not == nil
			entry.username.should == "kevin"
			entry.weight.should == 117
			entry.date.should == date.to_s
		end
	end
	describe "fitplan_controller.create_new_food()" do
		it "should successfully add valid user food" do
			cookies[:remember_token] = "0"
			UserProfile.signup("kevin", "secret", "0")
			req = {"username" => "kevin", "food" => "ice cream", "calories" => 9000, "serving" => "a lot"}
			resp = {"result" => UserProfile::SUCCESS}
			post '/profile/create_new_food', req.to_json, session
			response.body.should == resp.to_json
		end
		it "should error if calories is nonpositive" do
			cookies[:remember_token] = "0"
			UserProfile.signup("kevin", "secret", "0")
			req = {"username" => "kevin", "food" => "ice cream", "calories" => 0, "serving" => "a lot"}
			resp = {"result" => "Calories must be positive"}
			post '/profile/create_new_food', req.to_json, session
			response.body.should == resp.to_json
		end
		it "should error if calories is not a number" do
			cookies[:remember_token] = "0"
			UserProfile.signup("kevin", "secret", "0")
			req = {"username" => "kevin", "food" => "ice cream", "calories" => "derp", "serving" => "a lot"}
			resp = {"result" => "Calories must be an integer"}
			post '/profile/create_new_food', req.to_json, session
			response.body.should == resp.to_json
		end
	end
	puts "***end fitplan_func_spec.rb"
end

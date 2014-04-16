require File.expand_path("../../models/user_profile", __FILE__)
require File.expand_path("../../models/food_search", __FILE__)
require File.expand_path("../../models/workout_entry", __FILE__)
require 'date'
require 'json'

class FitplanController < ApplicationController

	def index
		# home page
	end

	def login_submit
		# receive JSON, log in registered user
		if !valid_json?(["username", "password"])
			return render(:json=>{}, status:500)
		end
		username = params[:username]
		password = params[:password]
		token = UserProfile.getNewToken()
		result = UserProfile.login(username, password, token)
		if result == UserProfile::SUCCESS
			cookies.permanent[:remember_token] = token
		end
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def signup_submit
		# receive JSON, sign up new user
		if !valid_json?(["username", "password"])
			return render(:json=>{}, status:500)
		end
		username = params[:username]
		password = params[:password]
		token = UserProfile.getNewToken()
		result = UserProfile.signup(username, password, token)
		if result == UserProfile::SUCCESS
			cookies.permanent[:remember_token] = token
		end
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def signout_submit
		# receive JSON, sign up new user
		result = UserProfile.signout(cookies[:remember_token])
		cookies.delete(:remember_token)
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def profile_form
		# profile form page, retrieve existing values
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		@defaults = UserProfile.getDefaults(@user)
	end

	def profile_form_submit
		# receive JSON, save profile form data
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		fields = ["feet", "inches", "weight", "desired_weight", "age", "gender"]
		if !valid_json?(fields)
			return render(:json=>{}, status:500)
		end
		result = UserProfile.setProfile(@user, fields, params)
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def profile
		# profile page
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		@today = Date.today.to_s
		@entries = UserProfile.getEntriesByDate(@user, @today)
		if @entries.class == String
			@message = @entries
		else
			@message = "You have #{@entries.length} entries for #{@today}."
		end
	end

	def add_food
		# respond to initial food search
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		if request.post?
			@food = params["food"]
			@results = FoodSearch.search(@food)
			return
		end
	end

	def get_calorie
		# respond to JSON request for calorie value
		if !valid_json?(["num"])
			return render(:json=>{}, status:500)
		end
		entry = FoodSearch.getCalorie(params["num"].to_i)
		if entry == nil
			return render(:json=>{"calorie"=>-1, "serving"=>""}, status:200)
		end
		return render(:json=>{"calorie"=>entry.calories, "serving"=>entry.serving}, status:200)
	end

	def add_food_submit
		# respond to JSON request to submit food entry
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		if !valid_json?(["num", "num_servings"])
			return render(:json=>{}, status:500)
		end
		entry = FoodSearch.getEntry(params["num"].to_i)
		result = UserProfile.addFood(@user, entry.food, entry.calories, entry.date,
			entry.serving, params["num_servings"])
		return render(:json=>{"result"=>result}, status: 200)
  end

  def add_weight
    @user = getUser(cookies[:remember_token])
    if @user == nil
      return
    end
    result = UserProfile.addWeightEntry(@user, params["weight"], Date.today.to_s)
    if result == UserProfile::SUCCESS
      return render(:json=>{"result"=>"success", "message"=>"Weight successfully added"})
    else
      return render(:json=>{"result"=>"failure", "message"=>result})
    end
  end

	def delete_food
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		if !valid_json?(["delete"])
			return render(:json=>{}, status:500)
		end
		delete = JSON.parse(params["delete"])
		result = UserProfile.deleteFood(@user, delete)
		return render(:json=>{"result"=>result}, status: 200)
	end

	def workout
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		@activities = WorkoutEntry.getActivities()
		@defaultActivity = "Running, 6 mph (10 min mile)"
		@workout = UserProfile.getWorkout(@user, Date.today.to_s)
		target_cal = @workout["intake"]-
			@workout["target"]-@workout["burned"]
		normal_cal = @workout["intake"]-
			@workout["normal"]-@workout["burned"]
		rec = UserProfile.getRecommended(@user, target_cal,
			normal_cal, @defaultActivity)
		@workout["rec_target"] = rec["rec_target"] # target for desired weight
		@workout["rec_normal"] = rec["rec_normal"] # maintain current weight
	end

	def add_workout_entry
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		result = UserProfile.addWorkoutEntry(@user,
			params[:activity], params[:minutes], Date.today.to_s)
		d = {}
		if result.class == String
			d["result"] = result
			d["burned"] = -1
		else
			d["result"] = UserProfile::SUCCESS
			d["burned"] = result
		end
		return render(:json=>d, status:200)
	end

	def get_recommended
		# [rate] = cal/(lb * hr)
		# [weight] = lb
		@user = getUser(cookies[:remember_token])
		if @user == nil
			return
		end
		if !valid_json?(["target_cal", "normal_cal", "activity"])
			return render(:json=>{}, status:500)
		end
		rec = UserProfile.getRecommended(@user, params["target_cal"],
			params["normal_cal"], params["activity"])
		return render(:json=>rec, status: 200)
	end

  def progress
    @user = getUser(cookies[:remember_token])
    if @user == nil
	  return
	end
    @userModel = UserProfile.find_by_username(getUser(cookies[:remember_token]))
    @calorieIntakeChartData = UserProfile.calorieIntakeChartData("a", 3)
    @weightChartData = UserProfile.weightChartData(@user, 3)
  end

	def test
		if !valid_json?([])
			return render(:json=>{}, status:500)
		end
		file = Tempfile.new(["rspec", ".txt"], "#{Rails.root}/tmp")
		result = system("rspec #{Rails.root}/spec/requests "+
			"--format documentation --out "+file.path)
		begin
			contents = file.readlines()
			i = contents.length-1
			line = ""
			while i > 0
				if contents[i].include?("failures")
					line = contents[i]
					break
				end
				i -= 1
			end
			fixline = ""
			line.each_char {|c|
				if c == '\n'
					fixline += " "
				else
					fixline += c
				end
			}
			line = fixline.split(" ")
			total = line[line.index("examples,")-1].to_i
			fails = line[line.index("failures")-1].to_i
			file.close
			output = contents.join()
			if fails == 0
				output = "All tests pass"
			end
			return render(:json=>{"nrFailed"=>fails, "output"=>output,
				"totalTests"=>total}, status:200)
		rescue => err
			return render(:json=>{"nrFailed"=>0, "output"=>"Unexpected error",
				"totalTests"=>10}, status:200)
		end
	end

	private
	def valid_json?(args)
		type = request.headers["Content-Type"].split(";")
		if !request.post?() || !(type.include?("application/json"))
			return false
		end
		for arg in args
			if !params.keys.include?(arg)
				return false
			end
		end
		return true
	end

	private
	def getUser(token)
		user = UserProfile.getUsername(token)
		if user == nil
			render('not_signed_in')
			return nil
		else
			return user
		end
	end

end

require "UserProfileModel"
require "FoodSearchModel"
require 'date'

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
		result = UserProfileModel.login(username, password)
		@user = username
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
		result = UserProfileModel.signup(username, password)
		@user = username
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def profile_form
		# profile form page
	end

	def profile_form_submit
		# receive JSON, save profile form data
		fields = ["feet", "inches", "weight", "desired_weight", "age"]
		if !valid_json?(fields)
			return render(:json=>{}, status:500)
		end
		result = UserProfileModel.setProfile("a", fields, params)
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def profile
		# profile page
		@entries = UserProfileModel.getEntries("a")
		@today = Date.today.to_s
		if @entries.class != Array
			@message = @entries
		else
			@message = "You have #{@entries.length} entries for #{@today}."
		end
	end

	def add_food
		# respond to initial food search
		if request.post?
			@food = params["food"]
			@results = FoodSearchModel.search(@food)
			return
		end
	end

	def get_calorie
		# respond to JSON request for calorie value
		if !valid_json?(["num"])
			return render(:json=>{}, status:500)
		end
		cal = FoodSearchModel.getCalorie(params["num"].to_i)
		if cal == nil
			return render(:json=>{"calorie"=>-1}, status:200)
		end
		return render(:json=>{"calorie"=>cal}, status:200)
	end

	def add_food_submit
		# respond to JSON request to submit food entry
		if !valid_json?(["num", "calorie"])
			return render(:json=>{}, status:500)
		end
		food = FoodSearchModel.getFood(params["num"].to_i)
		cal = params["calorie"].to_i
		date = Date.today.to_s
		result = UserProfileModel.addFood("a", food, cal, date)
		return render(:json=>{"result"=>result}, status: 200)
    end

    def workout
    	@target = UserProfileModel.getTarget("a")
    	@intake = UserProfileModel.getIntake("a", Date.today.to_s)
    	@recommended = UserProfileModel.getRecommended(@target, @intake)
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
end

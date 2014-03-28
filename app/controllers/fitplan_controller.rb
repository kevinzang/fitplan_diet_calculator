require File.expand_path("../../models/user_profile", __FILE__)
require File.expand_path("../../models/food_search", __FILE__)
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
		result = UserProfile.login(username, password)
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
		result = UserProfile.signup(username, password)
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
		result = UserProfile.setProfile("a", fields, params)
		resp = {"result"=>result}
		return render(:json=>resp, status:200)
	end

	def profile
		# profile page
		@today = Date.today.to_s
		@entries = UserProfile.getEntriesByDate("a", @today)
		if @entries.class == String
			@message = @entries
		else
			@message = "You have #{@entries.length} entries for #{@today}."
		end
	end

	def add_food
		# respond to initial food search
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
		if !valid_json?(["num", "num_servings"])
			return render(:json=>{}, status:500)
		end
		entry = FoodSearch.getEntry(params["num"].to_i)
		result = UserProfile.addFood("a", entry.food, entry.calories, entry.date,
			entry.serving, params["num_servings"])
		return render(:json=>{"result"=>result}, status: 200)
    end

    def delete_food
    	if !valid_json?(["delete"])
			return render(:json=>{}, status:500)
		end
		delete = JSON.parse(params["delete"])
		result = UserProfile.deleteFood("a", delete)
		return render(:json=>{"result"=>result}, status: 200)
	end

    def workout
    	@target = UserProfile.getTarget("a")
    	@intake = UserProfile.getIntake("a", Date.today.to_s)
    	@recommended = UserProfile.getRecommended(@target, @intake)
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
end

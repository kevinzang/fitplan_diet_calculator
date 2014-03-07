require "UserProfileModel"

class FoodSearchModel
	require 'open-uri'
	def self.readPage(path)
		# return html given url path
		file = open(path)
		contents = file.read
		file.close
		return contents
	end

	def self.search(food)
		# search for food
		# if results are found, save links in db and return list of results
		# else return nil
		FoodSearch.delete_all()
		food = food.gsub(" ", "_")
		path = "http://caloriecount.about.com/cc/"+
		"search.php?searchpro=#{food}&search_type=foods"
		contents = readPage(path)
		contents = contents.split('<ol style="clear:both;">') # split in two
		if contents.length == 1
			return ["No Results Found"] # no results found
		else
			contents = contents[1] # get second half
			endIndex = contents.index('</ol>')
			contents = contents[0..endIndex-1] # get table of results
			contents.delete!("\n")
			results = contents.split("</li>") # split table into entries
			(0..results.length-1).each do |i|
				index = results[i].index('<a')
				results[i] = results[i][index..-1]
				if results[i].count(")") > results[i].count("(")
					results[i] = "(" + results[i]
				end
				index = results[i].rindex('<a')
				link = results[i][index..-1] # get the last link
				index = link.index(">") # closing > to the <a
				link = link[0..index-2] # right before the ">
				index = link.index("<a href=")+9 # right after the "
				link = link[index..-1]
				link = "http://caloriecount.com" + link
				newEntry = FoodSearch.new(num:i, link:link, searched:false)
				newEntry.save()
			end
			return results
		end
	end

	def self.getCalorie(entryNum)
		# get calorie value for food entry with num = entryNum
		# return nil if cannot find food entry
		entry = FoodSearch.find_by(num:entryNum)
		if entry == nil
			return nil
		end
		if !entry.searched
			puts "searching"
			entry.searched = true
			entry.save
			contents = readPage(entry.link)
			contents = contents.split("<span class='food-stats-cal'>") # split in 2
			if contents.length == 1
				return nil
			end
			contents = contents[1] # get second half
			endIndex = contents.index("</span>")
			contents = contents[0..endIndex-1]
			contents.gsub!("\t", "")
			return contents
		end
		puts "nothing happened"
	end
end

class Defaults
	def self.WELCOME
		return "Welcome to Fitplan Diet Calculator!"
	end
	def self.PROFILE_FORM
	    return "Please complete your profile"
	end
end

class FitplanController < ApplicationController

	def index
		# home page
	end

	def login_submit
		# receive POST, log in registered user
		if !valid_json?("/login_submit", ["username", "password"])
			return render(:json=>{}, status:500)
		end
		username = params[:username]
		password = params[:password]
		result = UserProfileModel.login(username, password)
		resp = {"result"=>UserProfileModel.getErrorMessage(result)};
		return render(:json=>resp, status:200)
	end

	def signup_submit
		# receive POST, sign up new user
		if !valid_json?("/signup_submit", ["username", "password"])
			return render(:json=>{}, status:500)
		end
		username = params[:username]
		password = params[:password]
		result = UserProfileModel.signup(username, password)
		resp = {"result"=>UserProfileModel.getErrorMessage(result)};
		return render(:json=>resp, status:200)
	end

	def profile_form
		# profile form page
	end

	def profile
		# profile page
	end

	def searchFood
		# respond to initial food search
		if request.post?
			@food = params["food"]
			@results = FoodSearchModel.search(@food)
			return
		end
	end

	def getCalorie
		# respond to json request for calorie value
		type = request.headers["Content-Type"].split(";")
		if !request.post? || !type.include?("application/json")
			return render(:json=>{}, status:500)
		end
		if request.fullpath == "/search_food/get_calorie" &&
			params.keys.include?("num")
			cal = FoodSearchModel.getCalorie(params["num"].to_i)
			if cal == nil
				return render(:json=>{"calorie"=>-1}, status:200)
			end
			return render(:json=>{"calorie"=>cal}, status:200)
		else
			return render(:json=>{}, status:500)
		end
	end

	private
	def valid_json?(url, args)
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

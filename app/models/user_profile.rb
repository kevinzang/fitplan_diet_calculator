class UserProfile < ActiveRecord::Base
	require "food_entry"
	require "workout_entry"
	require "date"

  has_attached_file :profile_pic,
                    :default_url => '/anon_user.jpg',
                    :storage => :s3,
                    :s3_protocol => 'http',
                    :bucket => 'cs169_fitplan',
                    :s3_credentials => {
                        :bucket => 'cs169_fitplan',
                        :access_key_id => 'AKIAITJHHIG34RHDCVGA',
                        :secret_access_key => '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'
                    }

  validates_attachment_content_type :profile_pic, :content_type => /\Aimage/, :message => "ERROR: Invalid file format. jpg or png only."
  #validates_attachment_file_name :profile_pic, :matches => [/png\Z/, /jpe?g\Z/], :message => "ERROR: Invalid file format. jpg or png only."

	MAX_USERNAME_LENGTH = 128
	MAX_PASSWORD_LENGTH = 128

	SUCCESS = "SUCCESS"

	ERR_BAD_CREDENTIALS = "Incorrect username/password combination. Try again."

	ERR_USER_EXISTS = "Username already exists. Try again."

	ERR_BAD_USERNAME = "Username length must be at least 1 character "+
		"and at most #{MAX_USERNAME_LENGTH} characters. Try again."

	ERR_BAD_PASSWORD = "Password length must be at most "+
		"#{MAX_PASSWORD_LENGTH} characters. Try again."

	ERR_USER_NOT_FOUND = "Error: user not found"

	ERR_ACTIVITY_NOT_FOUND = "Error: activity not found"

	def self.validUsername?(username)
		return username != "" && username.length() <= MAX_USERNAME_LENGTH
	end

	def self.validPassword?(password)
		return password.length() <= MAX_PASSWORD_LENGTH
	end

	def self.isRegistered?(username)
		return UserProfile.find_by(username:username) != nil
	end

	def self.getNewToken()
		return SecureRandom.urlsafe_base64()
	end

	def self.getUsername(token)
		if token == nil
			return nil
		end
		user = UserProfile.find_by(remember_token:UserProfile.hash(token))
		if user == nil
			return nil
		end
		return user.username
	end

	def self.signup(username, password, token)
		new_user = UserProfile.find_by(username:username)
		if new_user != nil
			return ERR_USER_EXISTS
		end
		if !UserProfile.validUsername?(username)
			return ERR_BAD_USERNAME
		end
		if !UserProfile.validPassword?(password)
			return ERR_BAD_PASSWORD
		end
		encrypted_password = Digest::SHA1.hexdigest(password)
        new_user = UserProfile.new(username:username, password:encrypted_password,
            remember_token:UserProfile.hash(token))
		new_user.activity_level = 0
		new_user.weight_change_per_week_goal = 0.0
		new_user.gauge_level = 0
		new_user.last_login = Date.today.to_s
		new_user.save()
		return SUCCESS
	end

	def self.login(username, password, token)
		reg_user = UserProfile.find_by(username:username)
        encrypted_password = Digest::SHA1.hexdigest(password)

		if reg_user == nil
			return ERR_BAD_CREDENTIALS
		end
		if reg_user.password != encrypted_password
			return ERR_BAD_CREDENTIALS
		end
		reg_user.remember_token = UserProfile.hash(token)
		diff = (Date.today - Date.parse(reg_user.last_login)).to_i
		if diff == 1
			reg_user.gauge_level = [reg_user.gauge_level+1, 30].min
		elsif diff > 1
			reg_user.gauge_level = [reg_user.gauge_level-2*(diff-1), 0].max
		end
		reg_user.last_login = Date.today.to_s
		reg_user.save()
		return SUCCESS
	end

	def self.signout(token)
		user = UserProfile.find_by(remember_token:UserProfile.hash(token))
		if user != nil
			user.remember_token = nil
			user.save()
		end
		return SUCCESS
	end

	def self.getDefaults(username)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		values = {}
		for field in ["height", "weight", "desired_weight", "age", "gender", "activity_level", "weight_change_per_week_goal"]
			value = user.read_attribute(field)
			if value == nil
				values[field] = ""
			else
				if field == "height"
					values["feet"] = (value/12).to_s
					values["inches"] = (value%12).to_s
				else
					values[field] = value.to_s
				end
			end
		end
		return values
	end

	def self.setProfile(username, fields, params)
		valid = UserProfile.checkProfile(fields, params)
		if valid != SUCCESS
			return valid
		end
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		user.height = params["feet"].to_i*12 + params["inches"].to_i
		user.weight = params["weight"].to_i
		user.desired_weight = params["desired_weight"].to_i
		user.age = params["age"].to_i
		user.gender = params["gender"]
		user.activity_level = params["activity_level"].to_i
		user.weight_change_per_week_goal = params["weight_change_per_week_goal"].to_f
		user.save()
		return valid
  end

  def self.setPic(username, pic)
    user = UserProfile.find_by(:username => username)
    # validate exists
    if pic.nil?
      return "ERROR: Must upload a file"
    end
    # validate file size
    if pic.size > 5.megabytes
      return "ERROR: Maximum file size is 5 MB"
    end
    user.update(:profile_pic => pic)
    if !user.valid?
      return user.errors[:profile_pic][0]
    end
    user.save()
    return SUCCESS
  end

	def self.getEntries(username)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		return FoodEntry.where(username:username)
	end

	def self.getEntriesByDate(username, date)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		return FoodEntry.where(username:username, date:date.to_s)
	end

	def self.getWeightEntries(username)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		return WeightEntry.where(username: username)
	end

	def self.getCurrentWeight(username)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		list = WeightEntry.where(username: username)
		if list.length == 0
			return user.weight
		end
		list.sort!{|a,b| b.updated_at <=> a.updated_at}
		return list[0].weight
	end

	def self.getWeightEntriesInRange(username, range_in_months)
		return getWeightEntries(username).select{|entry| entry.date.to_date() >= Date.today - range_in_months.months}
	end

	def self.addWeightEntry(username, weight, date)
		user = UserProfile.find_by(username:username)
		if user.nil?
			return ERR_USER_NOT_FOUND
		end
		begin
			Float(weight)
		rescue
			return "Error: weight must be a number"
		end
		weight = weight.to_f.round.to_i
		if weight < 0
			return "Error: weight must be positive"
		end
		if weight > 1000
			return "Error: weight must be <= 1000"
		end
		entry = WeightEntry.find_by(username: username, date: date)
		if entry == nil
			entry = WeightEntry.new(username: username, date: date, weight: weight)
		else
			entry.update_attributes(weight: weight)
		end
		entry.save()
		return SUCCESS
	end

	def self.addUserFood(username, food, calories, serving)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		begin
			Integer(calories)
		rescue
			return "Calories must be an integer"
		end
		if food.nil? or food == ""
			return "Food field missing"
		end
		if serving.nil? or serving == ""
			return "Serving field missing"
		end
		food = food.to_s
		calories = calories.to_i
		serving = serving.to_s
		if calories <= 0
			return "Calories must be positive"
		end
		entry = UserFood.find_by(username:username, food:food, serving:serving)
		if entry == nil
			entry = UserFood.new(username:username, food:food, serving:serving, calories:calories)
		else
			entry.update_attributes(calories:calories)
		end
		entry.save()
		return SUCCESS
	end

	def self.getUserFoods(username, arg)
		return UserFood.where(username:username)
	end

	def self.deleteUserFood(username, food_names)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		entries = UserFood.where(username:username,
															food:food_names)
		for entry in entries
			index = food_names.index(entry.food)
			if index != nil
				entry.delete
				food_names.delete_at(index)
			end
		end
		return SUCCESS
	end

	def self.addFood(username, food, calorie, date, serving, num_servings)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		if num_servings == ""
			num_servings = "1"
		end
		if num_servings.to_f.to_s != num_servings &&
			num_servings.to_i.to_s != num_servings
			return "Error: must enter numeric value for number of servings"
		end
		if num_servings.to_i <= 0
			return "Error: number of servings must be positive"
		end
		entry = FoodEntry.new(username:username,
			food:food, calories:calorie.to_i, date:date,
			serving:serving, numservings:num_servings.to_i)
		entry.save()
		return SUCCESS
	end

	def self.deleteFood(username, food_names, date)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		entries = FoodEntry.where(username:username,
			food:food_names, date:date)
		for entry in entries
			index = food_names.index(entry.food)
			if index != nil
				entry.delete
				food_names.delete_at(index)
			end
		end
		return SUCCESS
	end

	def self.getWorkout(username, date)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		d = {}
		entries = FoodEntry.where(username:username, date:date.to_s)
		total = 0
		for entry in entries
			total += entry.calories * entry.numservings
		end
		d["intake"] = total
		entries = WorkoutEntry.where(username:username, date:date.to_s)
		total = 0
		for entry in entries
			total += entry.burned
		end
		d["burned"] = total
		for field in ["height", "age", "gender"]
			val = user.read_attribute(field)
			if val == nil || val == 0
				# profile not complete
				d["target"] = -1
				d["normal"] = -1
				return d
			end
		end
		if user.desired_weight == nil || user.desired_weight == 0
			d["target"] = -1
		else
			d["target"] = self.recommendedCalorieIntake(username)
		end
		if user.weight == nil || user.weight == 0
			d["normal"] = -1
		else
			d["normal"] = self.recommendedCalorieIntakeWeeklyGoal(username, 0)
		end
		return d
	end

	def self.getRecommended(username, target_cal, normal_cal, activity)
		user = UserProfile.find_by(username:username)
		rate = WorkoutEntry.getRate(activity)
		rec = {"rec_target"=>-1, "rec_normal"=>-1}
		if user == nil || rate == nil
			return rec
		end
		if !(user.weight == nil || user.weight == 0)
			rec["rec_target"] = [target_cal*60/rate/getCurrentWeight(username), 0].max().round(0)
			rec["rec_normal"] = [normal_cal*60/rate/getCurrentWeight(username), 0].max().round(0)
		end
		return rec
	end

	def self.addWorkoutEntry(username, activity, minutes, date)
		user = UserProfile.find_by(username:username)
		if user == nil
			return ERR_USER_NOT_FOUND
		end
		rate = WorkoutEntry.getRate(activity)
		if rate == nil
			return ERR_ACTIVITY_NOT_FOUND
		end
		if minutes == ""
			return "Must enter minutes of exercise"
		end
		if minutes.to_f.to_s != minutes &&
			minutes.to_i.to_s != minutes
			return "Minutes must be numeric value"
		end
		min = minutes.to_i
		if min <= 0
			return "Minutes must be positive"
		end
		if user.weight == nil || user.weight == 0
			return "Must enter your weight on your Profile Form"
		end
		entry = WorkoutEntry.new(username:username,
			activity:activity, minutes:min, date:date)
		entry.burned = (rate * getCurrentWeight(username) / 60.0 * min).round(0).to_i
		entry.save()
		entries = WorkoutEntry.where(username:username, date:date.to_s)
		total = 0
		for entry in entries
			total += entry.burned
		end
		return total
	end

	def self.weightChartData(username, range_in_months)
		weightEntries = getWeightEntriesInRange(username, range_in_months)
		if weightEntries == ERR_USER_NOT_FOUND
			return {}
		end
		if range_in_months < 0
			return {}
		end
		chartData = {}
		for weightEntry in weightEntries
			if chartData.has_key?(weightEntry.date)
				chartData[weightEntry.date] = [chartData[weightEntry.date], weightEntry.weight].max
			else
				chartData[weightEntry.date] = weightEntry.weight
			end
		end
		return chartData
  end

  def self.weightChartDataFriends(username, range_in_months)
    friendships = Friendship.where(:usernameFrom => username)
    weights = []
    for friendship in friendships do
      weights.push({"name" => friendship.usernameTo, "data" => weightChartData(friendship.usernameTo, range_in_months)})
    end
    weights.push({"name"=> username, "data" => weightChartData(username, range_in_months)})
  end

	def self.calorieIntakeChartData(username, range_in_months)
		foodEntries = UserProfile.getEntries(username)
		if foodEntries == ERR_USER_NOT_FOUND
			return nil
		end
		if range_in_months < 0
			return {}
		end
		if range_in_months > 12
			range_in_months = 12
		end
		chartData = {}
		for foodEntry in foodEntries
			if !(foodEntry.date.to_date < Date.today - range_in_months.months)
				if chartData.has_key?(foodEntry.date)
					chartData[foodEntry.date] += foodEntry.calories * foodEntry.numservings
				else
					chartData[foodEntry.date] = foodEntry.calories * foodEntry.numservings
				end
			end
		end
		return chartData
	end

	# Uses Harris-Benedict Equation
	def self.recommendedCalorieIntake(username)
		user = find_by(username: username)
		if user.nil?
			return nil
		end
		bmr = self.getBMR(user.height, getCurrentWeight(username), user.age, user.gender)
		scale_factor = 1.2 + 0.175 * user.activity_level
		# one pound of body weight is roughly equivalent to 3500 calories
		calorie_change_per_week = 3500 * user.weight_change_per_week_goal
		calorie_change_per_day = calorie_change_per_week / 7
		return scale_factor * bmr + calorie_change_per_day
	end

	def self.recommendedCalorieIntakeWeeklyGoal(username, weekly_goal)
		user = find_by(username: username)
		if user.nil?
			return nil
		end
		bmr = self.getBMR(user.height, getCurrentWeight(username), user.age, user.gender)
		scale_factor = 1.2 + 0.175 * user.activity_level
		# one pound of body weight is roughly equivalent to 3500 calories
		calorie_change_per_week = 3500 * weekly_goal
		calorie_change_per_day = calorie_change_per_week / 7
		return scale_factor * bmr + calorie_change_per_day
	end

	def self.reset()
		UserProfile.delete_all()
		FoodEntry.delete_all()
		WorkoutEntry.delete_all()
		WeightEntry.delete_all()
		Friendship.delete_all()
		FriendRequest.delete_all()
	end

	def self.populate()
		# create some entries for this week
		UserProfile.reset()
		UserProfile.signup("a", "", "")
		fields = {"feet"=>"5", "inches"=>"8", "weight"=>"160",
			"desired_weight"=>"155", "age"=>"20", "gender"=>"male",
			"activity_level"=>"1", "weight_change_per_week_goal"=>"-1.0"}
		UserProfile.setProfile("a", fields.keys, fields)
		week = []
		curr = Date.today
		while curr.wday > 0
			curr = curr - 1
		end
		for _ in 0..6
			week.insert(0, curr.to_s)
			curr = curr + 1
		end
		for day in week
			UserProfile.addFood("a", "Irresponsibly long food name for the glorious "+
				"day that is #{day}", 100, day, "Somewhat long description", "1")
			UserProfile.addFood("a", "Irresponsibly long food name for the glorious "+
				"day that is #{day}", 100, day, "Somewhat long description", "2")
			UserProfile.addFood("a", "Irresponsibly long food name for the glorious "+
				"day that is #{day}", 100, day, "Somewhat long description", "3")
		end
  end

  def self.print(object)
    p 'printing:'
    p object
  end

  def self.setup_for_demo()
    # if Rails.env.production?
    #   return
    # end

    # cleanup the dbs
    UserProfile.destroy_all()
    FoodEntry.delete_all()
    FoodSearch.delete_all()
    FriendRequest.delete_all()
    Friendship.delete_all()
    UserFood.delete_all()
    UserProfile.delete_all()
    WeightEntry.delete_all()
    WorkoutEntry.delete_all()

    date = Date.today - 5.days

    # main user
    UserProfile.signup("pikachu", "pikachu", "0")
    curr_user = UserProfile.find_by(:username => "pikachu")
    curr_user.height = 68
    curr_user.weight = 211
    curr_user.desired_weight = 160
    curr_user.gender = "male"
    curr_user.activity_level = 1
    curr_user.weight_change_per_week_goal = -2.0
    curr_user.gauge_level = 4
    curr_user.last_login = (Date.today - 1.days).to_s
    curr_user.save()
    data = File.open(Dir.pwd + '/spec/requests/files/pikachu.jpg')
    UserProfile.setPic("pikachu", data)
    WeightEntry.create(:username => "pikachu", :weight => 211, :date => (date + 1.days).to_s)
    WeightEntry.create(:username => "pikachu", :weight => 210.7, :date => (date + 2.days).to_s)
    WeightEntry.create(:username => "pikachu", :weight => 210.4, :date => (date + 3.days).to_s)
    WeightEntry.create(:username => "pikachu", :weight => 209.2, :date => (date + 4.days).to_s)
    WeightEntry.create(:username => "pikachu", :weight => 208.8, :date => (date + 5.days).to_s)
    FoodEntry.create(:username => "pikachu", :food => "Apple", :calories => 200, :date => (date + 5.days).to_s, :serving => "Unit", :numservings => 3)
    FoodEntry.create(:username => "pikachu", :food => "Salad", :calories => 500, :date => (date + 5.days).to_s, :serving => "Bowl", :numservings => 1)
    #
    FoodEntry.create(:username => "pikachu", :food => "Inn-N-Out Hamburger", :calories => 500, :date => (date + 4.days).to_s, :serving => "Unit", :numservings => 1)
    FoodEntry.create(:username => "pikachu", :food => "Inn-N-Out Fries", :calories => 700, :date => (date + 4.days).to_s, :serving => "Large", :numservings => 1)
    FoodEntry.create(:username => "pikachu", :food => "Orange Soda", :calories => 400, :date => (date + 4.days).to_s, :serving => "Cup", :numservings => 2)
    WorkoutEntry.create(:username => "pikachu", :date => (date + 4.days).to_s, :burned => 50)
    #
    FoodEntry.create(:username => "pikachu", :food => "Grilled Chipotle Chicken Salad", :calories => 600, :date => (date + 3.days).to_s, :serving => "unit", :numservings => 1)
    FoodEntry.create(:username => "pikachu", :food => "Jamba Juice Strawberry Wild", :calories => 400, :date => (date + 3.days).to_s, :serving => "unit", :numservings => 1)
    WorkoutEntry.create(:username => "pikachu", :date => (date + 3.days).to_s, :burned => 300)
    #
    FoodEntry.create(:username => "pikachu", :food => "House of Curries Vindaloo Chicken", :calories => 400, :date => (date + 2.days).to_s, :serving => "unit", :numservings => 1)
    WorkoutEntry.create(:username => "pikachu", :date => (date + 2.days).to_s, :burned => 200)
    # friend 1
    Friendship.create(:usernameFrom => "pikachu", :usernameTo => "teemo")
    Friendship.create(:usernameFrom => "teemo", :usernameTo => "pikachu")
    UserProfile.signup("teemo", "teemo", "1")
    data = File.open(Dir.pwd + '/spec/requests/files/teemo.jpg')
    UserProfile.setPic("teemo", data)
    WeightEntry.create(:username => "teemo", :weight => 206, :date => (date + 1.days).to_s)
    WeightEntry.create(:username => "teemo", :weight => 205.5, :date => (date + 2.days).to_s)
    WeightEntry.create(:username => "teemo", :weight => 205.2, :date => (date + 3.days).to_s)
    WeightEntry.create(:username => "teemo", :weight => 205, :date => (date + 4.days).to_s)
    WeightEntry.create(:username => "teemo", :weight => 204.9, :date => (date + 5.days).to_s)

    #friend 2
    Friendship.create(:usernameFrom => "pikachu", :usernameTo => "michael")
    Friendship.create(:usernameFrom => "michael", :usernameTo => "pikachu")
    UserProfile.signup("michael", "michael", "2")
    data = File.open(Dir.pwd + '/spec/requests/files/nike.jpg')
    UserProfile.setPic("michael", data)
    WeightEntry.create(:username => "michael", :weight => 200, :date => (date + 1.days).to_s)
    WeightEntry.create(:username => "michael", :weight => 201.2, :date => (date + 2.days).to_s)
    WeightEntry.create(:username => "michael", :weight => 199.5, :date => (date + 3.days).to_s)
    WeightEntry.create(:username => "michael", :weight => 199.3, :date => (date + 4.days).to_s)
    WeightEntry.create(:username => "michael", :weight => 199.2, :date => (date + 5.days).to_s)

    #from_request
    UserProfile.signup("ash", "ash", "3")
    FriendRequest.create(:usernameFrom => "ash", :usernameTo => "pikachu", :friendStatus => false)
    data = File.open(Dir.pwd + '/spec/requests/files/ash.png')
    UserProfile.setPic("ash", data)

    #to_request
    UserProfile.signup("godzilla", "godzilla", "4")
    FriendRequest.create(:usernameFrom => "pikachu", :usernameTo => "godzilla", :friendStatus => false)
    data = File.open(Dir.pwd + '/spec/requests/files/godzilla.png')
    UserProfile.setPic("godzilla", data)
=begin
    # instantiate users
    for i in 0..10
      username = 'user' + i.to_s
      password = 'password' + i.to_s
      height = 60 + i
      weight = 100 + 15 * i
      desired_weight = weight - i * 2
      age = 18 + rand(20)
      if rand(2) == 0
        gender = "male"
      else
        gender = "female"
      end
      remember_token = i.to_s
      activity_level = rand(5)
      weight_change_per_week_goal = -0.5 * rand(5)
      UserProfile.signup(username, password, remember_token)
      new_user = UserProfile.find_by(:username => username)
      new_user.height = height
      new_user.weight = weight
      new_user.desired_weight = desired_weight
      new_user.age = age
      new_user.gender = gender
      new_user.save()
    end

    # add weight entries
    for i in 0..10
      for j in 0..30
        username = 'user' + i.to_s
        date = (Date.today - j).to_s
        weight = getCurrentWeight(username)
        choice = rand(100)
        if choice < 5
          weight_entry = WeightEntry.new()
          weight_entry.username = username
          weight_entry.date = date
          weight_entry.weight = weight + 1
          weight_entry.save()
        elsif choice > 80
          weight_entry = WeightEntry.new()
          weight_entry.username = username
          weight_entry.date = date
          weight_entry.weight = weight - 1
          weight_entry.save()
        end
      end
    end

    # assign friends
    for i in 0..10
      for j in 0..10
        if i == j
          next
        end
        choice = rand(3)
        if choice == 0
            Friendship.create(:usernameFrom => 'user' + i.to_s, :usernameTo => 'user' + j.to_s)
            Friendship.create(:usernameFrom => 'user' + j.to_s, :usernameTo => 'user' + i.to_s)
        end
      end
    end
=end
  end

	private
	def self.checkProfile(fields, params)
		for key in fields
			if key == "gender"
				next
			end
			val = params[key]
			if val != "" && val.to_f.to_s != val &&
				val.to_i.to_s != val
				return "All fields must be numbers. Try again."
			elsif key != "weight_change_per_week_goal" && val.to_i < 0
				return "All fields must be non-negative. Try again."
			end
		end
		return SUCCESS
	end

	private
	def self.getBMR(height, weight, age, gender)
		if gender == "male"
			# bmr formula for men, rounded to nearest ten
			return (65 + 13.8*weight/2.2 + 5*height*2.54 - 6.8*age).round(-1)
		elsif gender == "female"
			# bmr formula for women, rounded to nearest ten
			return (655 + 9.6*weight/2.2 + 1.8*height*2.54 - 4.7*age).round(-1)
		else
			return 2000
		end
	end

	private
	def self.hash(token)
		return Digest::SHA1.hexdigest(token.to_s)
	end
end

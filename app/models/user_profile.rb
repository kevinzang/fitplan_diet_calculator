class UserProfile < ActiveRecord::Base
    require "food_entry"
    require "date"

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
        new_user = UserProfile.new(username:username, password:password,
            remember_token:UserProfile.hash(token))
 		new_user.save()
 		return SUCCESS
    end

    def self.login(username, password, token)
        reg_user = UserProfile.find_by(username:username)
        if reg_user == nil
            return ERR_BAD_CREDENTIALS
        end
        if reg_user.password != password
            return ERR_BAD_CREDENTIALS
        end
        reg_user.remember_token = UserProfile.hash(token)
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
        for field in ["height", "weight", "desired_weight", "age", "gender"]
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
        user.save()
        return valid
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

    def self.deleteFood(username, food_names)
        user = UserProfile.find_by(username:username)
        if user == nil
            return ERR_USER_NOT_FOUND
        end
        entries = FoodEntry.where(username:username,
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
        for field in ["height", "weight", "desired_weight", "age", "gender"]
            if user.read_attribute(field) == nil || user.read_attribute(field) == 0
                # profile not complete
                d["target"] = -1
                d["normal"] = -1
                d["rec_target"] = -1
                d["rec_normal"] = -1
                return d
            end
        end
        d["target"] = self.getBMR(user.height, user.desired_weight, user.age, user.gender)
        d["normal"] = self.getBMR(user.height, user.weight, user.age, user.gender)
        d["rec_target"] = self.getRecommended(d["intake"]-d["target"], 10, user.desired_weight)
        d["rec_normal"] = self.getRecommended(d["intake"]-d["normal"], 10, user.weight)
        return d
    end

    def self.reset()
        UserProfile.delete_all()
        FoodEntry.delete_all()
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
            elsif val.to_i < 0
                return "All fields must be non-negative. Try again."
            end
        end
        return SUCCESS
    end

    private
    def self.getBMR(height, weight, age, gender)
        if gender == "male"
            # bmr formula for men, rounded to nearest ten
            return (65 + 13.8*weight/2.2 +
            5*height*2.54 - 6.8*age).round(-1)
        elsif gender == "female"
            # bmr formula for women, rounded to nearest ten
            return (655 + 9.6*weight/2.2 +
            1.8*height*2.54 - 4.7*age).round(-1)
        else
            return 2000
        end
    end

    private
    def self.getRecommended(calories, rate, weight)
        # [rate] = cal/(kg * hr)
        # [weight] = lb
        return [calories*2.2*60/10/weight, 0].max().round(0)
    end

    private
    def self.hash(token)
        return Digest::SHA1.hexdigest(token.to_s)
    end
end

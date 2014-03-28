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

	def self.signup(username, password)
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
        new_user = UserProfile.new(username:username, password:password)
 		new_user.save()
 		return SUCCESS
    end

    def self.login(username, password)
        reg_user = UserProfile.find_by(username:username)
        if reg_user == nil
            return ERR_BAD_CREDENTIALS
        end
        if reg_user.password != password
            return ERR_BAD_CREDENTIALS
        end
        return SUCCESS
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
        if num_servings != "" && num_servings.to_f.to_s != num_servings &&
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

    def self.getTarget(username)
        return 2000
    end

    def self.getIntake(username, date)
        # date = today's date
        user = UserProfile.find_by(username:username)
        if user == nil
            return ERR_USER_NOT_FOUND
        end
        entries = FoodEntry.where(username:username, date:date.to_s)
        total = 0
        for entry in entries
            total += entry.calories
        end
        return total
    end

    def self.getRecommended(target, intake)
        diff = intake - target
        if diff <= 0
            return 0
        end
        return diff*60/500
    end

    def self.reset()
        UserProfile.delete_all()
        FoodEntry.delete_all()
    end

    private
    def self.checkProfile(fields, params)
        for key in fields
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
end

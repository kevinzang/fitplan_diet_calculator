class UserProfileModel
	@@MAX_USERNAME_LENGTH = 128
	@@MAX_PASSWORD_LENGTH = 128

	@@SUCCESS = "SUCCESS"

    @@ERR_BAD_CREDENTIALS = "Incorrect username/password combination. Try again."

    @@ERR_USER_EXISTS = "Username already exists. Try again."

    @@ERR_BAD_USERNAME = "Username length must be at least 1 character "+
            "and at most #{@@MAX_USERNAME_LENGTH} characters. Try again."

    @@ERR_BAD_PASSWORD = "Password length must be at most "+
            "#{@@MAX_PASSWORD_LENGTH} characters. Try again."

    @@ERR_USER_NOT_FOUND = "Error: user not found"

	def self.validUsername?(username)
		return username != "" && username.length() <= @@MAX_USERNAME_LENGTH
	end

	def self.validPassword?(password)
		return password.length() <= @@MAX_PASSWORD_LENGTH
	end

	def self.signup(username, password)
		new_user = UserProfile.find_by(username:username)
        if new_user != nil
            return @@ERR_USER_EXISTS
        end
        if !UserProfileModel.validUsername?(username)
            return @@ERR_BAD_USERNAME
        end
        if !UserProfileModel.validPassword?(password)
            return @@ERR_BAD_PASSWORD
        end
        new_user = UserProfile.new(username:username, password:password, entries:[])
 		new_user.save()
 		return @@SUCCESS
    end

    def self.login(username, password)
        reg_user = UserProfile.find_by(username:username)
        if reg_user == nil
            return @@ERR_BAD_CREDENTIALS
        end
        if reg_user.password != password
            return @@ERR_BAD_CREDENTIALS
        end
        return @@SUCCESS
    end

    def self.setProfile(username, fields, params)
        valid = UserProfileModel.checkProfile(fields, params)
        puts "VALID IS #{valid}"
        if valid != @@SUCCESS
            return valid
        end
        user = UserProfile.find_by(username:username)
        if user == nil
            return @@ERR_USER_NOT_FOUND
        end
        user.height = params["feet"].to_i*12 + params["inches"].to_i
        user.weight = params["weight"].to_i
        user.desired_weight = params["desired_weight"].to_i
        user.age = params["age"].to_i
        user.save()
        return valid
    end

    def self.checkProfile(fields, params)
        for key in fields
            puts "VALUE IS #{params[key]}"
            val = params[key]
            if val != "" && val.to_f.to_s != val &&
               val.to_i.to_s != val
                puts "GOT #{params[key].to_f.to_s} BUT EXPECTED #{params[key]}"
                return "All fields must be numbers. Try again."
            elsif val.to_i < 0
                return "All fields must be non-negative. Try again."
            end
        end
        return @@SUCCESS
    end

    def self.getEntries(username)
        user = UserProfile.find_by(username:username)
        if user == nil
            return @@ERR_USER_NOT_FOUND
        end
        entries = []
        for entry in user.entries
            entries.push(UserProfileModel.toEntry(entry))
        end
        return entries
    end

    def self.addFood(username, food, calorie, date)
        if food == nil
            return "Error: food could not be added"
        end
        user = UserProfile.find_by(username:"a")
        if user.entries.class != Array
            return "Error: food could not be added"
        else
            user.entries.push(UserProfileModel.toString([food, calorie, date]))
            user.save()
            return @@SUCCESS
        end
    end

    def self.getTarget(username)
        return 2000
    end

    def self.getIntake(username, date)
        # date = today's date
        user = UserProfile.find_by(username:username)
        if user == nil
            return @@ERR_USER_NOT_FOUND
        end
        total = 0
        for entry in user.entries
            entry = self.toEntry(entry)
            if entry[2] == date
                total += entry[1].to_i
            end
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

    def self.toString(entry)
        # entries are in [food, calorie, date] format
        return entry.join("||")
    end

    def self.toEntry(str)
        return str.split("||")
    end

    def self.reset()
    	UserProfile.delete_all()
    end
end
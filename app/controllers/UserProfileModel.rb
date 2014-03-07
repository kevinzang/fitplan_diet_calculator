class UserProfileModel
	@@MAX_USERNAME_LENGTH = 128
	@@MAX_PASSWORD_LENGTH = 128

	@@SUCCESS = 1

    # incorrect username/password combination
    @@ERR_BAD_CREDENTIALS = -1

    @@ERR_USER_EXISTS = -2

    @@ERR_BAD_USERNAME = -3

    @@ERR_BAD_PASSWORD = -4

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
        new_user = UserProfile.new(username:username, password:password)
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

    def self.getErrorMessage(status)
    	if status == @@SUCCESS
    		return "SUCCESS"
    	elsif status == @@ERR_USER_EXISTS
    		return "Username already exists. Try again."
    	elsif status == @@ERR_BAD_USERNAME
    		return "Username length must be at least 0 characters "+
    		"and at most #{@@MAX_USERNAME_LENGTH} characters. Try again."
    	elsif status == @@ERR_BAD_PASSWORD
    		return "Password length must be at most "+
    		"#{@@MAX_PASSWORD_LENGTH} characters. Try again."
    	elsif status == @@ERR_BAD_CREDENTIALS
    		return "Incorrect username/password combination. "+
    		"Try again."
    	else
            puts "STATUS: #{status}"
    		return "Unrecognized error code."
    	end
    end

    def self.reset()
    	UserProfile.delete_all()
    end
end


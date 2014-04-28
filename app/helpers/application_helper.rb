module ApplicationHelper
	def getUser(token)
		user = UserProfile.getUsername(token)
		if user == nil
			render('not_signed_in')
			return nil
		else
			return user
		end
	end

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

class FoodSearch < ActiveRecord::Base
	require 'open-uri'
	require 'date'
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
		food = food.gsub(" ", "+")
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
				results[i] = ActionController::Base.helpers.strip_links(results[i])
				newEntry = FoodSearch.new(num:i, food:results[i], link:link, searched:false)
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
			contents = readPage(entry.link)
			# get calorie
			cal = contents.split("<span class='food-stats-cal'>") # split in 2
			if cal.length == 1
				return nil
			end
			cal = cal[1] # get second half
			endIndex = cal.index("</span>")
			cal = cal[0..endIndex-1]
			cal.gsub!("\t", "")
			cal.gsub!("\n", "")

			# get serving description
			serving = contents.split('<div style="line-height:15px;">')
			if serving.length == 1
				return nil
			end
			serving = serving[1]
			endIndex = serving.index("</div>")
			serving = serving[0..endIndex-1]
			serving.gsub!("\t", "")
			serving.gsub!("\n", "")
			endIndex = serving.length-1
			while serving[endIndex] == " "
				endIndex -= 1
			end
			serving = serving[serving.index("Serving")..endIndex]
			serving = ActionController::Base.helpers.strip_tags(serving)
			entry.searched = true
			entry.calories = cal
			entry.serving = serving
			entry.date = Date.today.to_s
			entry.save()
			return entry
		end
		return nil
	end

	def self.getEntry(id)
		entry = FoodSearch.find_by(num:id)
		if entry == nil
			return nil
		end
		return entry
	end
end

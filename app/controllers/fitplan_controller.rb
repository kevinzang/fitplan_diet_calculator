class FitplanModel
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
				results[i].gsub!(")", "")
				index = results[i].rindex('<a')
				link = results[i][index..-1] # get the last link
				index = link.index(">") # closing > to the <a
				link = link[0..index-2] # right before the ">
				index = link.index("<a href=")+9 # right after the "
				link = link[index..-1]
				link = "http://caloriecount.com" + link
				newEntry = FoodSearch.new(num:i, link:link)
				newEntry.save()
			end
			return results
		end
	end
end

class FitplanController < ApplicationController
	def index
		# display home page
	end

	def profile
		# display profile page
	end

	def searchFood
		# respond to initial food search
		if request.post?
			@food = params["food"]
			@results = FitplanModel.search(@food)
			return
		end
	end
end

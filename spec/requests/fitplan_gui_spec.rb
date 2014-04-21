=begin
require 'spec_helper'
require File.expand_path("../../../app/models/user_profile", __FILE__)
require File.expand_path("../../../app/models/food_search", __FILE__)
require 'date'
require 'json'

# A note of caution: Capybara w/Selenium is a ... difficult testing framework to
# deal with at times. In particular, it doesn't seem to play nice with "before"
# and "after" blocks, which is why this code might look excessively redundant. Will
# try to refactor soon.  -JY

describe "Fitplan GUI Tests" do


    UserProfile.delete_all
    FoodEntry.delete_all
    FoodSearch.delete_all
    WorkoutEntry.delete_all
    FriendRequest.delete_all
    Friendship.delete_all
    WeightEntry.delete_all

    UserProfile.create!(username: 'Existing_User', password: '')

    #UserProfile.create!(
    #  username: username,
    #  password: '',
    #  height: 65,
    #  weight: 135,
    #  desired_weight: 130,
    #  age: 21,
    #  gender: 'male',
    #  activity_level: 1,
    #  weight_change_per_week_goal: -1
    #)

    describe "Logging in /Signing up" do

        before(:each) do
            visit '/'
        end

        it "should create new user", js: true do
            fill_in 'username', :with => 'Signup_New_User'
            click_on 'Sign up'
            page.should have_content 'Please fill out your profile:'
        end

        it "should not create already existing user", js: true do
            fill_in 'username', :with => 'Existing_User'
            click_on 'Sign up'
            page.should have_content 'Username already exists'
        end

        it "should not create user with empty username", js: true do
            click_on 'Sign up'
            page.should have_content 'Username length must be at least 1 character'
        end

        it "should not create user with username that exceeds max length", js: true do
            fill_in 'username', :with => 'Username_Too_Long' * 10
            click_on 'Sign up'
            page.should have_content 'at most 128 characters'
        end

        it "should not create user with password that exceeds max length", js: true do
            fill_in 'username', :with => 'Password_Too_Long'
            fill_in 'password', :with => 'A' * 129
            click_on 'Sign up'
            page.should have_content 'at most 128 characters'
        end

        it "should login already existing user", js: true do
            fill_in 'username', :with => 'Existing_User'
            click_on 'Log in'
            page.should have_content 'Welcome'
        end

        it "should not login new user", js: true do
            fill_in 'username', :with => 'Login_New_User'
            click_on 'Log in'
            page.should have_content 'Incorrect username/password combination'
        end

        it "should sign users out successfully", js: true do
            fill_in 'username', :with => 'Sign_Out'
            click_on 'Sign up'
            click_on 'Sign out'
            page.should have_content 'Welcome to Fitplan'
        end

        it "should not display navbar", js: true do
            page.should_not have_content "Workout Plan"
        end

        it "should display navbar after logging in", js: true do
            fill_in 'username', :with => 'Navbar'
            click_on 'Sign up'
            click_on 'Workout Plan'
            page.should have_content "Today's Stats"
        end

    end

    describe "Filling out the Profile Form" do

        before(:each) do
            visit '/'
        end

        it "should successfully submit new form", js: true do
            fill_in 'username', :with => 'Profile_Form_1'
            click_on 'Sign up'
            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Moderately Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'
            page.should have_content 'Profile details'
            click_on 'Edit Profile'
            page.should have_content 'Lose 1 lbs per week'
        end

        it "should successfully submit edited form", js: true do
            fill_in 'username', :with => 'Profile_Form_2'
            click_on 'Sign up'
            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Very Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'
            click_on 'Edit Profile'
            fill_in 'age', :with => '22'
            select('Lose 2 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'
            page.should have_content 'Profile details'
            click_on 'Edit Profile'
            page.should have_content 'Lose 1 lbs per week'
        end


        it "should not allow letters or negative numbers", js: true do
            fill_in 'username', :with => 'Profile_Form_3'
            click_on 'Sign up'
            fill_in 'feet', :with => 'five'
            click_on 'Submit Profile'
            page.should have_content 'must be numbers'
            fill_in 'feet', :with => '-5'
            click_on 'Submit Profile'
            page.should have_content 'non-negative'
            fill_in 'feet', :with => '5'
            click_on 'Submit Profile'
            page.should have_content 'Profile details'
        end

        it "should submit successfully with empty values", js: true do
            fill_in 'username', :with => 'Profile_Form_4'
            click_on 'Sign up'
            click_on 'Submit Profile'
            page.should have_content 'Profile details'
        end


    end

    describe "Adding Food Entries" do

        it "should display add food page", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE1'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            expect(page).to have_text('Cooked dry heat', wait: 5)

        end

        it "should display food along with calories and serving size", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE2'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            expect(page).to have_text('141 calories', wait: 5)
        end

        it "should display submitted food on profile page for today", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE3'
            click_on 'Sign up'
            click_on 'Profile'
            page.should_not have_content 'Cooked dry heat'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            fill_in 'serving0', :with => '582'
            click_on 'Add'
            page.should have_content '582'
        end

        it "should not display any results for 'alksnfdwl' or ''", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE4'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'alksnfdwl'
            click_on 'Add Food'
            expect(page).to have_text('No Results Found')
            click_on 'Profile'
            fill_in 'food', :with => ''
            click_on 'Add Food'
            expect(page).to have_text('No Results Found')
        end

        it "should not add food with an invalid 'servings number' input", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE5'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            fill_in 'serving0', :with => '-1'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept
            fill_in 'serving0', :with => 'a'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept
        end

        it "should display submitted food on profile page for yesterday", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE6'
            click_on 'Sign up'
            click_on 'Profile'
            find('#day-button-1').click
            page.should_not have_content 'Cooked dry heat'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            fill_in 'serving0', :with => '582'
            click_on 'Add'
            find('#day-button-1').click
            page.should have_content '582'
        end

        it "should display calorie intakes on profile page", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE7'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            click_on 'Add'
            page.should have_content 'Intake: 168 cal'
            page.should have_content 'Net Intake: 168 cal'
            find('#day-button-1').click
            page.should have_content 'Net Intake: 0 cal'
        end

    end

    describe "Deleting Food Entries" do

        it "should delete food entry from Profile Page for today", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE1'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            click_on 'Add'
            page.should have_content 'Cooked dry heat'
            find(".delete-0").set(true)
            click_on 'Delete selected entries'
            page.should_not have_content 'Cooked dry heat'
        end

        it "should do nothing if no food entries are present", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE3'
            click_on 'Sign up'
            click_on 'Profile'
            page.should have_content '-'
            click_on 'Delete selected entries'
            page.should have_content '-'
        end

        it "should delete food entry from Profile Page for yesterday", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE4'
            click_on 'Sign up'
            click_on 'Profile'
            find('#day-button-1').click
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            click_on 'Add'
            find('#day-button-1').click
            page.should have_content 'Cooked dry heat'
            find(".delete-1").set(true)
            click_on 'Delete selected entries'
            page.should_not have_content 'Cooked dry heat'
        end


    end

    describe "Workout Plan" do

        it "should display recommended caloric intake to maintain weight and achieve desired weight", js: true do
            visit '/'
            fill_in 'username', :with => 'WP1'
            click_on 'Sign up'
            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Moderately Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'
            click_on 'Workout Plan'
            page.should have_content '1964'
            page.should have_content '2464'
        end

        it "should display today's caloric intake", js: true do
            visit '/'
            fill_in 'username', :with => 'WP2'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            click_on 'Add'
            click_on 'Workout Plan'
            page.should have_content '168'
        end

        it "should add workout", js: true do
            visit '/'
            fill_in 'username', :with => 'WP3'
            click_on 'Sign up'

            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Moderately Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'

            click_on 'Workout Plan'
            select('Archery', :from => 'activity')
            fill_in 'minutes', :with => '20'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept
            page.should have_content '72'
        end

        it "should display accurate stats for today", js: true do
            visit '/'
            fill_in 'username', :with => 'WP4'
            click_on 'Sign up'

            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Moderately Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'

            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            click_on 'Add'

            click_on 'Workout Plan'
            select('Archery', :from => 'activity')
            fill_in 'minutes', :with => '20'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept
            page.should have_content '96'
        end

        it "should display default suggested workout activity", js: true do
            visit '/'
            fill_in 'username', :with => 'WP5'
            click_on 'Sign up'
            click_on 'Workout Plan'
            page.should have_content 'Running, 10 mph'
        end

        it "should display suggested workout times", js: true do
            visit '/'
            fill_in 'username', :with => 'WP6'
            click_on 'Sign up'

            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '5'
            fill_in 'weight', :with => '135'
            fill_in 'desired_weight', :with => '130'
            fill_in 'age', :with => '21'
            choose 'gender_male'
            select('Moderately Active', :from => 'activity_level')
            select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
            click_on 'Submit Profile'

            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            fill_in 'serving0', :with => '30'
            click_on 'Add'

            click_on 'Workout Plan'
            page.should have_content '301'
            page.should have_content '252'

            fill_in 'minutes', :with => '20'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept

            page.should have_content '288'
            page.should have_content '239'

            select('Bird watching', :from => 'rec_activity')
            page.should have_content '1147'
            page.should have_content '952'
        end

        it "should switch between workout tips", js: true do
            visit '/'
            fill_in 'username', :with => 'WP7'
            click_on 'Sign up'
            click_on 'Workout Plan'
            page.should have_content 'The best way to'
            page.should_not have_content 'Having a small'
            find('#tip-button-2').click
            page.should_not have_content 'The best way to'
            page.should have_content 'Having a small'
        end

    end


    describe "FAQ" do

        it "should display none of the answers initially", js: true do
            visit '/'
            fill_in 'username', :with => 'FAQ1'
            click_on 'Sign up'
            click_on 'FAQ'
            page.should_not have_content 'FitPlan is a personal food diary'
        end

        it "should display answers when question is clicked", js: true do
            visit '/'
            fill_in 'username', :with => 'FAQ2'
            click_on 'Sign up'
            find('#question-2').click
            page.should have_content 'FitPlan is a personal food diary'
            page.should_not have_content 'When you tell FitPlan'
        end
    end

    describe "Friends" do

        it "should display sent/received friend requests and accepted/deleted friends", js: true do
            visit '/'
            fill_in 'username', :with => 'Friend1a'
            click_on 'Sign up'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend1b'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'friend_request', :with => 'Friend1a'
            click_on 'Send Friend Request'
            find('#expand-requests').click
            page.should have_content 'Friend1a'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend1a'
            click_on 'Log in'
            find('#expand-requests').click
            page.should have_content 'Friend1b'
            find('#accept-Friend1b').click
            page.should have_content 'Friends (1)'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend1b'
            click_on 'Log in'
            page.should have_content 'Friends (1)'
            find('#delete-Friend1a').click
            page.driver.browser.switch_to.alert.accept
            page.should have_content 'Friends (0)'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend1a'
            click_on 'Log in'
            page.should have_content 'Friends (0)'
        end

        it "should not send request to someone who already requested you or who is already your friend", js: true do
            visit '/'
            fill_in 'username', :with => 'Friend2a'
            click_on 'Sign up'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend2b'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'friend_request', :with => 'Friend2a'
            click_on 'Send Friend Request'
            fill_in 'friend_request', :with => 'Friend2a'
            click_on 'Send Friend Request'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend2a'
            click_on 'Log in'
            page.should have_content 'Requests (1)'
            fill_in 'friend_request', :with => 'Friend2b'
            click_on 'Send Friend Request'
            page.driver.browser.switch_to.alert.accept
            page.should have_content 'Friends (0)'
            find('#expand-requests').click
            find('#accept-Friend2b').click
            fill_in 'friend_request', :with => 'Friend2b'
            click_on 'Send Friend Request'
            page.driver.browser.switch_to.alert.accept
            page.should have_content 'Friends (1)'
        end

        it "should not send request to yourself", js: true do
            visit '/'
            fill_in 'username', :with => 'Friend3a'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'friend_request', :with => 'Friend3a'
            click_on 'Send Friend Request'
            page.driver.browser.switch_to.alert.accept
        end

        it "should find a friend with a similar goal", js: true do
            visit '/'
            fill_in 'username', :with => 'Friend4a'
            click_on 'Sign up'
            fill_in 'weight', :with => '200'
            fill_in 'desired_weight', :with => '100'
            click_on 'Submit Profile'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend4b'
            click_on 'Sign up'
            fill_in 'weight', :with => '200'
            fill_in 'desired_weight', :with => '100'
            click_on 'Submit Profile'
            click_on 'Find New Friend'
            page.driver.browser.switch_to.alert.accept
            find('#expand-requests').click
            page.should have_content 'Friend4a'
            click_on 'Sign out'
            fill_in 'username', :with => 'Friend4a'
            click_on 'Log in'
            find('#expand-requests').click
            page.should have_content 'Friend4b'
        end

        it "should not send request to nonexistent user", js: true do
            visit '/'
            fill_in 'username', :with => 'Friend5'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'friend_request', :with => 'Nonexistent_user'
            click_on 'Send Friend Request'
            page.driver.browser.switch_to.alert.accept
            find('#expand-requests').click
            page.should_not have_content 'Nonexistent_user'
        end

    end


    describe "Empty profile form" do

        it "should display empty values / default info when profile form not completed", js: true do
            visit '/'
            fill_in 'username', :with => 'EmptyProfile1'
            click_on 'Sign up'
            click_on 'Submit Profile'
            find('#expand-details').click
            page.should have_content '0 lbs'
            click_on 'Workout Plan'
            page.should have_content 'Complete profile form!'
            fill_in 'minutes', :with => '20'
            click_on 'Add'
            page.driver.browser.switch_to.alert.accept
        end

    end

end
=end

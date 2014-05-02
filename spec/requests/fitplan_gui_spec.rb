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

    UserProfile.create!(username: 'a', password: '')
    UserProfile.create!(username: 'Existing_User', password: 'password')

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
            fill_in 'password', :with => ''
            click_on 'Sign up'
            page.should have_content 'Please fill out your profile:'
        end

        it "should not create already existing user", js: true do
            fill_in 'username', :with => 'Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            page.should have_content 'Username already exists'
        end

        it "should not create user with empty username", js: true do
            click_on 'Sign up'
            page.should have_content 'Username length must be at least 1 character'
        end

        it "should not create user with username that exceeds max length", js: true do
            fill_in 'username', :with => 'Username_Too_Long' * 10
            fill_in 'password', :with => ''
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
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            page.should have_content 'Welcome'
        end

        it "should not login new user", js: true do
            fill_in 'username', :with => 'Login_New_User'
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            page.should have_content 'Incorrect username/password combination'
        end

        it "should sign users out successfully", js: true do
            fill_in 'username', :with => 'Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            click_on 'Sign out'
            page.should have_content 'Welcome to Fitplan'
            click_on 'Profile'
            page.should have_content 'You are not signed in'
        end

    end

    describe "Filling out the Profile Form" do

        before(:each) do
            visit '/'
        end

        it "should successfully submit new form", js: true do
            fill_in 'username', :with => 'Profile_Form_1'
            fill_in 'password', :with => 'password'
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
            page.should have_content 'Welcome'
            click_on 'Edit Profile'
            page.should have_content 'Lose 1 lbs per week'
        end

        it "should successfully submit edited form", js: true do
            fill_in 'username', :with => 'Profile_Form_2'
            fill_in 'password', :with => 'password'
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
            page.should have_content 'Welcome'
            click_on 'Edit Profile'
            page.should have_content 'Lose 1 lbs per week'
        end


        it "should not allow letters or negative numbers", js: true do
            fill_in 'username', :with => 'Profile_Form_3'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            fill_in 'feet', :with => 'five'
            click_on 'Submit Profile'
            page.should have_content 'must be numbers'
            fill_in 'feet', :with => '-5'
            click_on 'Submit Profile'
            page.should have_content 'non-negative'
            fill_in 'feet', :with => '5'
            click_on 'Submit Profile'
            page.should have_content 'Welcome'
        end

        it "should submit successfully with empty values", js: true do
            fill_in 'username', :with => 'Profile_Form_4'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Submit Profile'
            page.should have_content 'Welcome'
        end


    end

    describe "Adding Food Entries" do

        it "should display add food page", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE1'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            expect(page).to have_text('Cooked dry heat', wait: 5)

        end

        it "should display food along with calories and serving size", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE2'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            expect(page).to have_text('141 calories', wait: 5)
        end

        it "should display submitted food on profile page", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE3'
            fill_in 'password', :with => 'password'
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
            fill_in 'password', :with => 'password'
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
            fill_in 'password', :with => 'password'
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


    end

    describe "Deleting Food Entries" do

        it "should delete food entry from Profile Page", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE1'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            click_on 'Add'
            page.should have_content 'Cooked dry heat'
            find("#check-0").set(true)
            click_on 'Delete selected entries'
            page.should_not have_content 'Cooked dry heat'
        end

        it "should delete two food entries from Profile Page", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE2'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            click_on 'Add'
            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            click_on 'Add'
            fill_in 'food', :with => 'hamburger'
            click_on 'Add Food'
            click_on 'Ground Beef'
            click_on 'Add'
            find("#check-0").set(true)
            find("#check-2").set(true)
            click_on 'Delete selected entries'
            page.should_not have_content 'Cooked dry heat'
            page.should_not have_content 'Ground Beef'
            page.should have_content 'Pizza - With Cheese'
        end

        it "should do nothing if no food entries are present", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE3'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            page.should have_content 'You have 0 entries'
            click_on 'Delete selected entries'
            page.should have_content 'You have 0 entries'
        end

    end

    describe "Workout Plan" do

        it "should display recommended caloric intake to maintain weight and achieve desired weight", js: true do
            visit '/'
            fill_in 'username', :with => 'WP1'
            fill_in 'password', :with => 'password'
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
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'pizza'
            click_on 'Add Food'
            click_on 'Pizza - With Cheese'
            click_on 'Add'
            click_on 'Workout Plan'
            page.should have_content '168'
        end

        #it "should add workout", js: true do
        #    visit '/'
        #    fill_in 'username', :with => 'WP3'
        #    fill_in 'password', :with => 'password'
        #    click_on 'Sign up'

        #    fill_in 'feet', :with => '5'
        #    fill_in 'inches', :with => '5'
        #    fill_in 'weight', :with => '135'
        #    fill_in 'desired_weight', :with => '130'
        #    fill_in 'age', :with => '21'
        #    choose 'gender_male'
        #    select('Moderately Active', :from => 'activity_level')
        #    select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
        #    click_on 'Submit Profile'

        #    click_on 'Workout Plan'
        #    select('Archery', :from => 'activity')
        #    fill_in 'minutes', :with => '20'
        #    click_on 'Add Workout'
        #    page.driver.browser.switch_to.alert.accept
        #    page.should have_content '72'
        #end

        #it "should display accurate stats for today", js: true do
        #    visit '/'
        #    fill_in 'username', :with => 'WP4'
        #    click_on 'Sign up'

        #    fill_in 'feet', :with => '5'
        #    fill_in 'inches', :with => '5'
        #    fill_in 'weight', :with => '135'
        #    fill_in 'desired_weight', :with => '130'
        #    fill_in 'age', :with => '21'
        #    choose 'gender_male'
        #    select('Moderately Active', :from => 'activity_level')
        #    select('Lose 1 lbs per week', :from => 'weight_change_per_week_goal')
        #    click_on 'Submit Profile'

        #    fill_in 'food', :with => 'pizza'
        #    click_on 'Add Food'
        #    click_on 'Pizza - With Cheese'
        #    click_on 'Add'

        #    click_on 'Workout Plan'
        #    select('Archery', :from => 'activity')
        #    fill_in 'minutes', :with => '20'
        #    click_on 'Add Workout'
        #    page.driver.browser.switch_to.alert.accept
        #    page.should have_content '96'
        #end

        it "should display default suggested workout activity", js: true do
            visit '/'
            fill_in 'username', :with => 'WP5'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Workout Plan'
            page.should have_content 'Running, 10 mph'
        end

    end

    describe "User's Progress" do

        it "should display user's current and desired weight", js: true do
            visit '/'
            fill_in 'username', :with => 'UP1'
            fill_in 'password', :with => 'password'
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
            click_on 'Progress'
            page.should have_content '130'
            page.should have_content '135'
        end

    end


end
=end
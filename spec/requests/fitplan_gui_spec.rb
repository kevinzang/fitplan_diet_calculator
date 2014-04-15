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

    describe "Logging in /Signing up" do

        before(:each) do
            visit '/'
        end

        it "should create new user", js: true do
            fill_in 'username', :with => 'Signup_New_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            page.should have_content 'Height:'
        end

        it "should not create already existing user", js: true do
            fill_in 'username', :with => 'Signup_Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Home'
            fill_in 'username', :with => 'Signup_Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            page.should have_content 'Username already exists'
        end

        it "should login already existing user", js: true do
            fill_in 'username', :with => 'Login_Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Home'
            fill_in 'username', :with => 'Login_Existing_User'
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            page.should have_content 'Profile Page'
        end

        it "should not login new user", js: true do
            fill_in 'username', :with => 'Login_New_User'
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            page.should have_content 'Incorrect username/password combination'
        end

        it "should sign users out successfully", js: true do
            fill_in 'username', :with => 'Signout_User'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
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
            click_on 'Submit Profile'
            page.should have_content 'Profile Page'
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
            click_on 'Submit Profile'
            click_on 'Edit Profile'
            fill_in 'age', :with => '22'
            click_on 'Submit Profile'
            page.should have_content 'Profile Page'
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
            page.should have_content 'Profile Page'
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

        it "should display food along with calories and serving size", js: true do
            visit '/'
            fill_in 'username', :with => 'AFE3'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'

            page.should_not have_content 'Cooked dry heat'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            expect(page).to have_text('Serving Size 1/2 breast', wait: 5)
            fill_in 'serving0', :with => '582'
            click_on 'Add'
            page.should have_content '582'
        end

    end

    describe "Deleting Food Entries" do

        it "should delete food entry from Profile Page", js: true do
            visit '/'
            fill_in 'username', :with => 'DFE'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            click_on 'Profile'
            fill_in 'food', :with => 'chicken'
            click_on 'Add Food'
            click_on 'Chicken, Breast, Meat Only - Cooked dry heat, Roasted, Grilled, Broiled'
            click_on 'Add'
            page.should have_content 'Cooked dry heat'
            check 'delete'
            click_on 'Delete selected entries'
            page.should_not have_content 'Cooked dry heat'
        end

    end

    describe "Workout Plan" do

        it "should display workout information", js: true do
            visit '/'
            fill_in 'username', :with => 'WP'
            fill_in 'password', :with => 'password'
            click_on 'Sign up'
            fill_in 'feet', :with => '5'
            fill_in 'inches', :with => '7'
            fill_in 'weight', :with => '155'
            fill_in 'desired_weight', :with => '150'
            fill_in 'age', :with => '20'
            choose 'gender_male'
            click_on 'Submit Profile'
            fill_in 'food', :with => 'carrots'
            click_on 'Add Food'
            click_on 'Carrots, Baby - Raw'
            fill_in 'serving1', :with => '60'
            click_on 'Add'
            click_on 'Workout Plan'
            page.should have_content "Today's intake: 1800 cal"
        end

    end

end

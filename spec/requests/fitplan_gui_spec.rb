require 'spec_helper'
require File.expand_path("../../../app/models/user_profile", __FILE__)
require File.expand_path("../../../app/models/food_search", __FILE__)
require 'date'
require 'json'

describe "Fitplan GUI Tests" do

    UserProfile.delete_all
    UserProfile.signup('a', '')

    #describe "Login/Signup Page" do

    #    before(:each) do
    #        visit '/'
    #    end

    #    it "should create new user", js: true do
    #        fill_in 'username', :with => 'Signup_New_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Sign up'
    #        page.should have_content 'Height:'
    #    end

    #    it "should not create already existing user", js: true do
    #        fill_in 'username', :with => 'Signup_Existing_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Sign up'
    #        click_on 'Home'
    #        fill_in 'username', :with => 'Signup_Existing_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Sign up'
    #        page.should have_content 'Username already exists'
    #    end

    #    it "should login already existing user", js: true do
    #        fill_in 'username', :with => 'Login_Existing_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Sign up'
    #        click_on 'Home'
    #        fill_in 'username', :with => 'Login_Existing_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Log in'
    #        page.should have_content 'Profile Page'
    #    end

    #    it "should not login new user", js: true do
    #        fill_in 'username', :with => 'Login_New_User'
    #        fill_in 'password', :with => 'password'
    #        click_on 'Log in'
    #        page.should have_content 'Incorrect username/password combination'
    #    end

    #end

    describe "Profile Form Page" do

        UserProfile.signup('Profile_Form_2', 'password')

        it "should successfully submit form", js: true do
            visit '/'
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

        it "should display edit profile page", js: true do
            visit '/'
            fill_in 'username', :with => 'Profile_Form_2'
            fill_in 'password', :with => 'password'
            click_on 'Log in'
            click_on 'Edit Profile'
            page.should have_content 'Please fill out your profile'
        end

    end

end

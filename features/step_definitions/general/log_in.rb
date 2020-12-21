# frozen_string_literal: true

# Contains steps definitions for log in procedures

# User -----------------------------------------------------------------------------------------------------------------

# This step requires @customer != nil
# Use @requires_mandate tav on your scenario to initialize @customer
Given(/^user logs in with the credentials$/) do
  step "user navigates to home page"
  step "user is on the home page"
  step "user opens cms burger menu [mobile view only]"
  step 'user clicks on "Einloggen" link'
  step "user is on the login page"
  step "user enters their email data"
  step "user enters their password data"
  step 'user clicks on "Login" button'
  step "user is on the manager page"
end

# TODO: see if there is a way to implement the solution without using %{} for better step readability
Given(/^user logs in with the credentials and closes "start demand check" modal$/) do
  steps %{
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DoDemandcheckModal         | control          |
    And user logs in with the credentials
    And user closes "start demand check" modal
    }
end

# Admin ----------------------------------------------------------------------------------------------------------------

Given(/^admin is logged in ops ui$/) do
  credentials = Repository::Credentials.ops_ui_admin_credentials
  step "admin navigates to admin login page"
  step "admin enters \"#{credentials['username']}\" into E-Mail input field"
  step "admin enters \"#{credentials['password']}\" into Passwort input field"
  step 'admin clicks on "Login" button'
  step "admin is on the admin landing page"
end

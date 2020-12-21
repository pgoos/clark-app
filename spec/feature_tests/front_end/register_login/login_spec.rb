# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/login/login_form_page"

RSpec.describe "Login Cases", :browser, :timeout, :slow, :clark_context, type: :feature, js: true do
  let!(:login_page) { LoginFormPage.new }

  before { login_page.visit_login }

  context "with registered user" do
    let!(:user) { create(:user, email: "test@test.de", password: "Somepassword123") }

    it "verifies user can successfully login into the webapp" do
      login_page.login_user "test@test.de", "Somepassword123"
      login_page.expect_login_success_msg
    end

    it "verifies user cannot Login with Clark WebApp with invalid email id" do
      # Verify user cannot Login with Clark App with Invalid Password length
      login_page.login_user "test@test.de", "short"
      login_page.expect_wrong_password_msg

      # "Verify user cannot Login with Clark WebApp with wrong email id"
      login_page.login_user "nonexistent@test.de", "Somepassword123"
      login_page.expect_wrong_data_msg
    end

    it "verifies user can reset password" do
      login_page.click_forgot_password
      login_page.fill_in_forgot_pass_email user.email # "nonexistent@test.de"
      login_page.click_new_password_btn
      login_page.expect_recover_email_message
    end
  end

  context "when not registered user" do
    it "shows message informing e-mail will be sent as long as it is registered" do
      login_page.click_forgot_password
      login_page.fill_in_forgot_pass_email "nonexistent@test.de"
      login_page.click_new_password_btn
      login_page.expect_recover_email_message
    end
  end
end

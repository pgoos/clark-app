# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/account/change_password_page.rb"
require "./spec/support/features/page_objects/ember/login/login_form_page.rb"

RSpec.describe 'User forgot password and change', :timeout, :slow, :clark_context, type: :feature, js: true do
  let(:change_password_page) { ChangePasswordPage.new }
  let(:login_page) { LoginFormPage.new }

  let!(:tokens) { Devise.token_generator.generate(User, :confirmation_token) }

  let!(:user) do
    user = create(:user, email: 'test@clark.de', mandate: create(:mandate))
    user.update_attributes(confirmed_at: nil, confirmation_token: tokens.last, confirmation_sent_at: Time.zone.now)
    user
  end

  context "modal resseting password" do
    it "shows reset password instructions successfully sent message" do
      login_page.visit_login
      login_page.click_forgot_password
      login_page.expect_forgot_password_popup

      login_page.fill_in_forgot_pass_email "test-test@clark-clark.de"
      login_page.click_new_password_btn

      login_page.expect_recover_email_message
    end
  end

  it 'Verify user can reset password successfully' do
    password_reset_token = user.send_reset_password_instructions
    change_password_page.visit_reset_pass password_reset_token
    change_password_page.expect_change_password_popup
    change_password_page.fill_in_password 'short', 'short'
    change_password_page.click_cta
    change_password_page.expect_wrong_passsword_msg
    change_password_page.fill_in_password 'SomePassword123', 'SomePassword123'
    change_password_page.click_cta
    change_password_page.expect_manager_page
  end

  it 'Verify user can not reset password successfully(passwort micmatch)' do
    password_reset_token = user.send_reset_password_instructions
    change_password_page.visit_reset_pass password_reset_token
    change_password_page.expect_change_password_popup
    change_password_page.fill_in_password 'SomePassword123', 'Mismatch123'
    change_password_page.click_cta
    change_password_page.expect_password_mismatch_msg
  end
end

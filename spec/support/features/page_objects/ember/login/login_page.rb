# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class LoginPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale           = locale
    @path_to_manager  = "/#{locale}/app/manager"
    @path_to_password = "/#{locale}/app/password-reset"
    @path_to_set_creds = "/#{locale}/app/set-credentials"
    @path_to_login     = "/#{locale}/app/login"
  end

  def go_to_login
    visit(@path_to_login)
    page.assert_current_path(@path_to_login)
  end

  def go_to_manager
    visit(@path_to_manager)
  end

  def go_to_set_creds
    visit(@path_to_set_creds)
  end

  def expect_on_reset_password
    page.assert_current_path(@path_to_password)
  end

  def expect_on_set_creds
    page.assert_current_path(@path_to_set_creds)
  end

  def expect_on_manager
    page.assert_current_path(@path_to_manager, wait: 10)
  end

  def expect_error_msg
    page.assert_selector('.ig__error-msg')
  end

  def submit_reset_form
    find(".btn-primary").click
  end

  def submit_creds_form
    find(".btn-primary").click
  end

  # checking error validation on inputs for various login forms
  def expect_password_error(amount)
    page.assert_selector('.capybara-password-input .ig__error-msg', count: amount)
  end

  def expect_email_error
    page.assert_selector('.capybara-email-input .ig__error-msg')
  end

  def expect_no_password_error
    page.assert_no_selector('.capybara-password-input .ig__error-msg')
  end

  # fill in various inputs
  def fill_in_login_username(email)
    fill_in 'mandate_login_email', with: email
  end

  def fill_in_login_password(password)
    fill_in 'mandate_login_password', with: password
  end

  def fill_in_password_one(password)
    fill_in 'mandate_password', with: password
  end

  def fill_in_password_two(password)
    fill_in 'mandate_password_repeat', with: password
  end

  def fill_in_email(email)
    fill_in 'mandate_login_email', with: email
  end

  # Fill in the forms
  def set_password(password)
    fill_in 'mandate_password', with: password
    fill_in 'mandate_password_repeat', with: password
  end

  def login(user)
    fill_in 'mandate_login_email', with: user.email
    fill_in 'mandate_login_password', with: user.password
  end

  def click_submit
    find('.btn-primary').click
  end
end

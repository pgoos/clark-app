# frozen_string_literal: true

require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class LoginFormPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_login = "/#{locale}/login"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_login
    visit @path_to_login
    page.assert_selector('input#user_email')
    page.assert_selector('input#user_password')
    page.assert_selector('a.btn--facebook')
    find('.btn-primary')
  end

  def click_register_button
    first(:link, '.register-btn').click
  end

  def click_forgot_password
    find('.new_password').click
  end

  def login_user(username, password)
    visit @path_to_login
    fill_in 'user_email', with: username
    fill_in 'user_password', with: password
    find('.btn-primary').click
  end

  def fill_in_forgot_pass_email(email)
    find('div.modal__body').fill_in('user_email', with: email)
  end

  def click_new_password_btn
    find('div.modal__body').find('.btn-primary').click
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_recover_email_message
    page.assert_text I18n.t("send_password.text")
  end

  def expect_login_success_msg
    page.assert_text("#{I18n.t('devise.sessions.user.signed_in')}")
  end

  def expect_invalid_email_type
    page.assert_text("Please include an '@' in the email address.")
  end

  def expect_wrong_password_msg
    page.assert_text("#{I18n.t('devise.failure.invalid')}")
  end

  def expect_wrong_data_msg
    page.assert_text("#{I18n.t('devise.failure.not_found_in_database')}")
  end

  def expect_forgot_password_popup
    page.assert_selector('.forgot-password__title')
    page.assert_selector('.forgot-password__text')
    within '.modal__body' do
      assert_selector('#user_email')
      assert_selector('.btn-primary')
    end
  end
end

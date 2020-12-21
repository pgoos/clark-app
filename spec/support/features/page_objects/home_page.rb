# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class HomePage < PageObject
  attr_reader :path

  def initialize(locale=I18n.locale)
    @path_to_home_page = "/#{locale}"
  end
  # ----------------
  # Page interactions
  #-----------------

  def navigate_home
    visit @path_to_home_page
    # assert_selector('.homepage__left-bg-image__intro__title')
    # assert_selector('.new_registration')
  end

  def click_register_button
    find(".register-btn").click
  end

  def click_login_button
    click_link(I18n.t("signin").to_s)
  end

  def click_meinkonto_button
    click_link(I18n.t("application.page_navigation.account").to_s)
  end

  def click_register_user
    fill_in "user_email", with: "test@clark.de"
    fill_in "user_password", with: Settings.seeds.default_password
    find(".homepage_submit").click
  end

  # ----------------
  # RSpec matcher
  #-----------------
end

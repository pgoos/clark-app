# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class EditUserAccountPage < PageObject
  attr_reader :path, :form_action

  def initialize(locale=I18n.locale)
    @locale = locale
    @path = polymorphic_path(%i[edit account user], locale: @locale)
    @form_action = polymorphic_path(%i[account user], locale: @locale)
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit path
  end

  def fill_form
    fill_in "user_email", with: "batman@test.clark.de"
    fill_in "user_password", with: Settings.seeds.default_password
    fill_in "user_password_confirmation", with: Settings.seeds.default_password
  end

  def blank_form
    fill_in "user_email", with: ""
  end

  def submit_form
    find(".edit_user").find(:xpath, "//input[@type='submit']").click
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_failure
    expect(page.find(".page-header__flash--failure")).to have_content(I18n.t("account.users.update.failure"))
    expect(page).to have_xpath("//form[@action='#{form_action}']")
    expect(page).to have_current_path(form_action)
  end

  def expect_success
    expect(page.find(".page-header__flash--success")).to have_content(I18n.t("account.users.update.success"))
    expect(page).to have_xpath("//form[@action='#{form_action}']")
    expect(page).to have_current_path(path)
  end
end

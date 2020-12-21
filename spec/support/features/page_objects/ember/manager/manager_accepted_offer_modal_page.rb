# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class ManagerAcceptedOfferModal < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{locale}/app/manager"
    @path_to_invite_friend = "/#{locale}/app/invitations"
  end

  def visit_page
    visit @path_to_cockpit
    # allow for the skeleton view
    # FLAKY
    # page.assert_selector(".capybara-contracts-list")
  end

  def refresh_page_apply_localStorage
    page.driver.browser.navigate.refresh
  end

  def expect_feedback_modal
    page.assert_selector("#feedbackModal")
  end

  def expect_no_feedback_modal
    page.assert_no_selector("#feedbackModal")
  end

  def expect_rate_modal
    page.assert_selector("#rateUsModal", visible: true)
  end

  def expect_no_rate_modal
    page.assert_no_selector("#rateUsModal")
  end

  def close_rate_modal
    page.assert_selector("#rateUsModal")
    find(".ember-modal__body__close").click
  end

  def set_localStorage_rateable
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('mandate', JSON.stringify({info:{just_accepted_offer:true}}))"
    )
  end

  def reset_localStorage_rating_settings
    Capybara.current_session.execute_script "window.localStorage.removeItem('mandate')"
  end

  def set_done_offer_business_event
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('clark-user-journey', JSON.stringify({states: ['show_feedback_modal_offer_accepted']}))"
    )
  end

  def reset_business_events
    Capybara.current_session.execute_script(
      "window.localStorage.removeItem('clark-user-journey')"
    )
  end

  def set_accepted_offer_local
    Capybara.current_session.execute_script(
      "window.localStorage.setItem('show_feedback_modal_offer_accepted', true)"
    )
  end

  def reset_accepted_offer_local
    Capybara.current_session.execute_script(
      "window.localStorage.removeItem('show_feedback_modal_offer_accepted')"
    )
  end
end

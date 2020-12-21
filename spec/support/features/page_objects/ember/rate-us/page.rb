require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RateUsPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_manager = "/#{locale}/app/manager"
    @emberHelper = EmberHelper.new
  end

  # Navigation helpers to go to views at the start of tests
  def navigate_manager
    visit @path_to_manager
    mock_and_clean
  end

  def navigate_product productID
    visit "/#{locale}/app/manager/products/#{productID}"
    mock_and_clean
  end

  def mock_and_clean
    clean_up
    set_seen_other_modals
  end

  def click_was_helpful
    find('.manager__product__details__message__feedback__ctas__cta--helpful').click
  end

  def assert_landed
    page.assert_no_selector('.manager__contracts__cards-list__aspect')
  end

  # Checking that user can or cannot see the rate us modal
  def assert_rate_visible
    page.assert_selector('#rateUsModal')
  end

  def assert_rate_not_visible
    page.assert_no_selector('#rateUsModal')
  end

  # Set a user journey event on the clark user journey store
  def set_event(event)
    Capybara.current_session.execute_script "window.localStorage.setItem('clark-user-journey', JSON.stringify({states: #{event}}))"
  end

  # Clears the journey and clark rate us events like old ratings and so on
  def clean_up
    Capybara.current_session.execute_script "window.localStorage.removeItem('mandate');window.localStorage.removeItem('clark-rating');window.localStorage.removeItem('clark-user-journey');"
  end

  def set_seen_other_modals
    Capybara.current_session.execute_script "window.localStorage.setItem('manager', JSON.stringify({'add-bu-insurance-seen': true,'add-insurances-seen':true}))"
  end

  # Set the default version as one behined so we trigger rating, as only rated old version
  def set_rating(rating: '5', states: '[]', version: '171')
    Capybara.current_session.execute_script "window.localStorage.setItem('mandate', JSON.stringify({'info': {'rating_modal_shown_frequency': 1}}))"
  end

  def set_user_rate_before
    Capybara.current_session.execute_script "let now = Date.now(); window.localStorage.setItem('mandate', JSON.stringify({'info': {'cta_bewerten': true, 'cta_bewerten_timestamp': now}}));"
  end

  def close_rating_modal
    return unless page.has_css?("#rateUsModal")

    find("#rateUsModal .ember-modal__body__close").click
  end
end

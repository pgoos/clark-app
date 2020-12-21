# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class HeaderPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale          = locale
    @path_to_manager = "/#{locale}/app/manager"
    @contractsHeaderLink = ".page-navigation__link--contracts"
    @optimisationsHeaderLink = ".page-navigation__link--optimisations"
    @profileHeaderLink = ".page-navigation__link--profile"
  end

  def navigate_manager
    visit(@path_to_manager)
    page.assert_current_path(@path_to_manager)
  end

  def expect_no_invite_friend_link
    expect(page).not_to have_selector(".page-navigation__link--invite")
  end

  def expect_versicherungen
    page.assert_selector(@contractsHeaderLink)
  end

  def expect_optimisations
    page.assert_selector(@optimisationsHeaderLink)
  end

  def expect_my_profile
    page.assert_selector(@profileHeaderLink)
  end

  def expect_click_header_go_to_manager
    click_manager
    page.assert_current_path(@path_to_manager)
  end

  # Interactions
  def click_optimisations
    find(@optimisationsHeaderLink).click
    page.assert_text(:visible, "Falls sich deine Lebenssituation verändert hat, solltest du den Bedarfscheck aktualisieren.")
  end

  def click_manager
    find(@contractsHeaderLink).click
    page.assert_selector(".capybara-contracts-list", visible: true)
  end
end

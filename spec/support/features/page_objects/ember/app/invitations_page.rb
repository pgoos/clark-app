# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"

class InvitationsPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/invitations"
    @path_to_manager = "/#{locale}/app/manager"
  end

  def visit_page
    visit(@path_to_page)
    page.assert_current_path(@path_to_page)
  end

  def expect_no_sub_text
    expect(page).not_to have_selector(".refer-friend__exp-text")
  end

  def expect_no_header_text
    expect(page).not_to have_selector(".refer-friend__header__top-row")
    expect(page).not_to have_selector(".refer-friend__header__bottom-row")
  end

  def expect_no_banner
    expect(page).not_to have_selector(".text-over-image")
  end

  def expect_redirected_to_manager
    visit(@path_to_page)
    page.assert_current_path(@path_to_manager)
  end
end

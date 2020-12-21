# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class CockpitPreviewPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path_to_cockpit_preview = "/#{locale}/app/mandate/cockpit-preview"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_cockpit_preview
  end


  # Matchers
  def expect_score
    page.assert_selector(".cockpit-preview--new__preview--score", visible: true)
  end

  def expect_cards_one
    page.assert_selector(".cockpit-preview--new__preview--cards-one", visible: true)
  end

  def expect_cards_two
    page.assert_selector(".cockpit-preview--new__preview--cards-two", visible: true)
  end

  def expect_cta
    page.assert_selector(".cockpit-preview--new__preview--cta", visible: true)
  end

  def expect_cockpit_preview_page
    find(".btn-primary").assert_text(I18n.t("manager.insurances.index.empty_states.add_insuarance_cta").to_s)
    page.assert_selector(".cockpit-preview--animate")
    page.assert_selector(".wizard-cockpit-preview")
  end

  # Interactions
  def click_page
    find(".manager__cockpit--entire-wrapper").click
  end

  def navigate_click(classname, location)
    btn = find(classname)
    btn.click
    assert_current_path("/#{locale}/app/#{location}")
  end

  def navigate_to(location)
    @emberHelper.set_up_ember_transition_hook
    visit "/#{locale}/app/#{location}"
    @emberHelper.wait_for_ember_transition
  end

  def reach_control_variation(location)
    assert_current_path("/#{locale}/app/#{location}")
  end

  def click_weiter
    find("a", text: I18n.t("next").to_s).click
  end

  def click_versicherungen_hinz
    find(".manager__cockpit__add-insurances-cta__btn").click
  end

  # Misc (sleeps etc)
  def wait_for_animations
    sleep 0.4
  end
end

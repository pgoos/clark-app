# frozen_string_literal: true

require "./spec/support/features/page_objects/page_object"
require "./spec/support/features/page_objects/ember/ember_helper"

class OptimizationTab < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @ember_helper = EmberHelper.new
    @path_to_manager = "/#{locale}/app/manager"
    @path_to_optimization = "/#{locale}/app/manager/recommendations"
    @path_to_pre_demandcheck = "/#{locale}/app/demandcheck/intro"
  end

  def visit_page
    visit @path_to_optimization
  end

  def expect_no_skeleton
    page.assert_selector(".manager__optimisations__wrapper--loaded", wait: 30)
  end

  def visit_page_no_loaded_assert
    visit @path_to_optimization
  end

  def optimization_page_visited
    page.assert_current_path(@path_to_optimization)
    find(".manager__optimisations__wrapper")
  end

  def has_title(text)
    expect(find(".manager__optimisations__title--desktop").text).to eq(text)
  end

  def has_three_verticals(*verticals)
    expect(verticals.size).to eq 3
    page.assert_selector(".capybara-optimisation-intro-title")
    expect(verticals).to eq optimisations_intro_titles.map(&:text)
  end

  def has_recommendations(*expected_recommendations)
    expect(top_optimisations.map(&:text)).to eq(expected_recommendations)
  end

  def has_vertical_scores(*scores)
    expect(vertical_amount_actioned.map(&:text)).to eq scores
  end

  def bottom_link_text(text)
    expect(find(".manager__optimisations__re-do-demandcheck__text").text).to eq(text)
  end

  def expect_cta_for_add_offer_works
    find(".manager__cockpit__add-insurances-cta__btn").click
    page.assert_selector(".ember-modal__body__header--add-more-insurance")
    button = find(".add-category-modal__btn--gkv")
    navigate_click(button, "select-category")
  end

  def importance_info_for_verticals(*importances)
    expect(top_row_importance.map(&:text)).to eq importances
  end

  def click_vertical_one_info
    find(".capybara-optimisation-intro-icon", match: :first).click
  end

  def vertical_one_has_info_text(text)
    element = find(".capybara-optimisation-overlay-intro", match: :first)
    expect(element.text).to eq text
  end

  def vertical_one_info_has_percentage_info(text)
    find(".capybara-optimisation-overlay-copy", match: :first, text: text)
  end

  def vertical_one_hide_info
    find(".capybara-optimisation-overlay-info-icon", match: :first).click
  end

  def expect_questionnaire_in_progress_card_state
    page.assert_selector(".manager__optimisations__optimisation__third-row__status-text")
  end

  def expect_no_questionnaire_in_progress_card_state
    page.assert_no_selector(".manager__optimisations__optimisation__third-row__status-text")
  end

  def click_card(optimisation_id)
    find(".manager__optimisations__optimisation[data-id='#{optimisation_id}']").click
  end

  def expect_modal
    page.assert_selector("#optimisationModal")
  end

  def expect_no_modal
    page.assert_no_selector("#optimisationModal")
  end

  def expect_demandcheck_reminder_modal
    page.assert_selector("#demandcheckReminderModal")
  end

  def close_demandcheck_reminder_modal
    return unless page.has_css?("#demandcheckReminderModal")

    find("#demandcheckReminderModal .ember-modal__body__close").click
  end

  def expect_navigated_to_offer(offer_id)
    expect_to_be_at("offer/#{offer_id}")
  end

  def expect_to_be_at(location)
    expect(current_path).to eq("/#{@locale}/app/#{location}")
  end

  def should_toggle_recommendations
    find(".manager__optimisations__wrapper")
    find(".manager__optimisations__optimisation-list-toggleable__arrow").click
    find(".manager__optimisations__optimisation-list-toggleable")
  end

  def should_not_toggle_recommendations
    find(".manager__optimisations__wrapper")
    vertical = page.all(".manager__optimisations__optimisation-list--optimisations")[0]
    vertical.assert_no_selector(".manager__optimisations__optimisation-list-toggleable__arrow")
  end

  def expect_still_on_optimisations
    page.assert_current_path(@path_to_optimization)
  end

  def see_reccommendation(recommendation)
    page.assert_selector(".manager__optimisations__optimisation.card-list__item[data-id='#{recommendation.id}']")
  end

  def expect_optimisations
    page.assert_selector(".manager__optimisations__optimisation.card-list__item", minimum: 1)
  end

  def expect_empty_things
    expect(find(".manager__optimisations__optimisation-list__done__text--things").text).to eq("#{I18n.t('manager.todolist.recommendations_done.msg_things')}")
  end

  def expect_no_invite_link
    page.assert_no_selector("page-navigation__link--invite")
  end

  # Clicking on an item x should take us to y page
  def navigate_click(element, location)
    @ember_helper.ember_transition_click(element)
    page.assert_current_path("/#{@locale}/app/#{location}")
  end

  private

  def top_row_importance
    page.all(".manager__optimisations__optimisation__top-row__importance")
  end

  def vertical_amount_actioned
    page.all(".capybara-optimisation-intro-actioned")
  end

  def optimisations_intro_titles
    page.all(".capybara-optimisation-intro-title")
  end

  def top_optimisations
    page.all(".manager__optimisations__optimisation__top-row__title")
  end
end

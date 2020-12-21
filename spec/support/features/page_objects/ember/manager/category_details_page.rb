require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class CategoryDetailsPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @emberHelper = EmberHelper.new
  end

  def visit_page id
    visit "/#{locale}/app/manager/categories/#{id}"
  end

  # Page object helpers
  def expect_standard_functionality(category)
    page.assert_text(category.name.to_s)
    # Should have the correct importance
    page.assert_text("#{I18n.t('manager.todolist.importance.very_important')}")
    # Should show the map for this guy
    page.assert_selector('.capybara-manager__category__intro__map')
    # Should not have a questionnaire button
    expect(page).not_to have_selector('.capybara-manager__category__intro__ctas__cta__button--questionnaire')
  end

  def expect_quality_standards
    page.assert_selector(".capybara-category-details-quality-standards")
  end

  def expect_no_quality_standards
    page.assert_no_selector('.capybara-category-details-quality-standards')
  end

  def expect_no_ark
    expect(page).not_to have_selector(".qs-stats__robo-row__icon")
  end

  def expect_clark_service
    page.assert_selector(".capybara-category-details-clark-service")
  end

  def expect_no_clark_service
    page.assert_no_selector('.capybara-category-details-clark-service')
  end

  def expect_no_map
    expect(page).to_not have_selector('.capybara-manager__category__intro__map')
  end

  def expect_questionnaire_button
    page.assert_selector('.capybara-manager__category__intro__ctas__cta__button--questionnaire')
  end

  def expect_navigated_to_correct_questionnaire(identifier)
    navigate_click(".capybara-manager__category__intro__ctas__cta__button--questionnaire",
                   "questionnaire/#{identifier}?source=category/details:recommendations")
  end

  def expect_compliance_text
    page.assert_selector(".qs-stats__robo__figures--gkv")
    page.assert_text("#{I18n.t('quality_standards.robo.favourable_contribution')}")
  end

  def expect_no_compliance_text
    page.assert_no_selector(".qs-stats__robo__gkv")
  end

  # ----------------
  # Helper functions
  #-----------------
  def navigate_click(classname, location)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end
end

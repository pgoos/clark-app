require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class ProductDetailsPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @emberHelper = EmberHelper.new
  end

  def visit_page id
    visit "/#{locale}/app/manager/products/#{id}"
    page.assert_current_path("/#{locale}/app/manager/products/#{id}")
  end

  # Page object helpers
  def expect_standard_elements(product)
    category = page.find('.capybara-product-details-category')
    company = page.find('.capybara-product-details-company')
    expect(category.text).to eq("#{word_hypen product.category.name}")
    expect(company.has_text?(product.company.name))
    page.assert_selector('.capybara-product-overview')
    premium_shows_correct_value("#{product.premium_price} #{product.premium_price_currency} #{I18n.t("manager.periods.#{product.premium_period}")}")
    page.assert_selector('.capybara-manager__product__details__stats__map')
    page.assert_selector('.manager__product__details__rating__container')
    page.assert_selector('.capybara-product-tips')
  end

  def premium_shows_correct_value(string)
    premium = page.find('.capybara-product-premium')
    expect(premium.has_text?(string))
  end

  def expect_no_ratings
    # ratings at the bottom
    expect(page).not_to have_selector('.manager__product__details__rating__container')

    # ratings at the top
    expect(page).not_to have_selector('.capybara-product-rating')
  end

  def expect_sales_fee_in_details
    expect(find('.capybara-product-details-list', match: :first).text).to include(I18n.t('manager.products.show.acquisition'))
  end

  def expect_contract_end_in_details
    expect(find('.capybara-product-details-list', match: :first).text).to include(I18n.t('manager.products.show.contract_ended_at'))
  end

  def expect_no_offer_button
    expect(page).to_not have_selector('.manager__product__details__message__ctas__cta--offer')
  end

  def advice_has_content(content)
    expect(find('.manager__product__details__message__content', match: :first).text).to eq(content)
  end

  def expect_standard_message_elements
    page.assert_selector(".manager__product__details__message__content")
    expect(find('.manager__product__details__message__header').text).to eq("#{I18n.t('manager.products.advice.title')}")
  end

  def expect_no_messages_at_top
    expect(page).not_to have_selector(".manager__product__details__message__content")
  end

  def expect_linked_questionnaire(questionnaire)
    expect(find('.manager__product__details__message__ctas__cta').text).to eq("#{I18n.t('manager.products.advice.start_questionnaire')}")
    navigate_click(".manager__product__details__message__ctas__cta",
                   "questionnaire/#{questionnaire.identifier}?source=products/details:click-optimise")
  end

  def expet_no_questionnaire_button
    expect(page).not_to have_selector('.manager__product__details__message__ctas__cta--default-cta')
  end

  def expect_helpful_buttons
    page.assert_selector('.manager__product__details__message__feedback')
  end

  def expect_helpful_thanks_message
    page.assert_selector('.manager__product__details__message__feedback__copy--thanks-message')
  end

  def expect_no_helpful_buttons
    expect(page).not_to have_selector(".manager__product__details__message__feedback")
  end

  def expect_documents(amount)
    page.assert_selector('.capybara-document-upload')
    page.assert_selector('.capybara-uploaded-document-card', visible: true, count: amount)
  end

  def expect_coverage_features
    page.assert_selector('.capybara-coverages', visible: true)
    coverages = page.find('.capybara-coverages')
    coverages.assert_selector('.capybara-list-item', visible: true, count: 3)

    expect(all(".capybara-list-item-desc")[0]).not_to have_selector('.tick-icon-fill')
    expect(all(".capybara-list-item-desc")[1]).not_to have_selector('.tick-icon-fill')
    expect(all(".capybara-list-item-desc")[2]).not_to have_selector('.tick-icon-fill')
  end

  def expect_duration_data
    page.assert_selector('.capybara-product-duration')
  end

  def expect_no_duration_data
    expect(page).not_to have_selector('.capybara-product-duration')
  end

  def expect_offer_button
    page.assert_selector('.manager__product__details__message__ctas__cta--offer', count: 1, visible: true)
  end

  def expect_questioannire_will_be_analized
    page.assert_selector('.manager__product__details__message__done-questionnaire')
  end

  def exect_no_questioannire_status
    expect(page).not_to have_selector('.manager__product__details__message__done-questionnaire')
  end

  def exect_no_offer_sent_text
    expect(page).not_to have_selector('.capybara-product-duration')
  end

  def expect_offer_ready_text(offer, product)
    category = word_hypen(product.category_name)
    recommended = offer.recommended_option
    company = word_hypen(recommended.product.company.name)
    expect(find('.manager__product__details__message__content', match: :first).text).to eq("#{I18n.t('manager.products.advice.offer_sent', category_name: category, recommended_company_name: company)}")
  end

  # ----------------
  # Helper functions
  #-----------------

  def click_was_helpful
    find('.manager__product__details__message__feedback__ctas__cta--helpful').click
  end

  def click_was_not_helpful
    find('.manager__product__details__message__feedback__ctas__cta--unhelpful').click
  end

  def navigate_click(classname, location)
    find(classname).click
    page.assert_current_path("/#{locale}/app/#{location}")
  end

  def navigate_to(location)
    @emberHelper.set_up_ember_transition_hook
    visit "/#{locale}/app/#{location}"
    @emberHelper.wait_for_ember_transition
  end
end

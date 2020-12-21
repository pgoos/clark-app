require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class OfferPagesPageObject < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
  end

  def expect_no_quality_standards_seciton
    page.assert_no_selector(".offers__offer__standards__wrapper")
  end

  def expect_quality_standards_seciton
    page.assert_selector(".offers__offer__standards__wrapper")
  end

  def expect_no_clark_service
    page.assert_no_selector(".offer-checkout__details__bottom-trust")
  end

  def expect_clark_service
    page.assert_selector(".offer-checkout__details__bottom-trust")
  end

  def expect_no_trust_logos
    page.assert_no_selector(".cucumber-trust-icons")
  end

  def expect_trust_logos
    page.assert_selector(".cucumber-trust-icons")
  end

  def expect_no_agent
    expect(page).not_to have_selector(".offer-checkout-avatar-row")
  end

  def expect_agent
    page.assert_selector(".offer-checkout-avatar-row")
  end

  def expect_no_profil_change_link
    page.assert_no_selector(".offer-checkout__details__overview__data__profile")
  end

  def see_no_vergleich_document
    page.assert_no_selector('.offers__offer__document__icon-link')
  end

  def see_no_pdf_link
    page.assert_no_selector('.offer-details__options__option__pdflink__link')
  end

  def see_pdf_link
    page.assert_selector('.offer-details__options__option__pdflink__link')
  end

  def see_vergleich_document
    page.assert_selector('.offers__offer__document__icon-link')
  end

  def see_offers
    page.assert_selector('.offer-details__options__option__box', count: 3)
  end

  def click_next
    find('.btn-primary').click
  end

  def expect_on_offerview(opportunity)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunity.id}")
  end

  def expect_on_confirmation(opportunity)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunity.id}/confirmation")
  end

  def expect_on_data(opportunity, offer_option_id)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunity.id}/data/#{offer_option_id}")
  end

  def expect_on_iban(opportunity)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunity.id}/iban")
  end

  def expect_on_checkout(opportunity, offer_option_id)
    page.assert_current_path("/#{@locale}/app/offer/#{opportunity.id}/checkout/#{offer_option_id}")
  end

  def expect_correct_serivce_hours
    page.assert_selector('.offer-checkout__description_text--appointment-time')
    page.assert_text('Wir sind von Mo. - Fr. von 8 - 20 Uhr erreichbar.')
  end

  def open_more_info_modal
    page.find(".offers__offer__standards").find(".btn").click
  end

  def expect_compliance_text
    page.assert_selector(".qs-stats__robo__figures--bottom-row-gkv")
    page.assert_text("#{I18n.t('quality_standards.robo.favourable_contribution')}")
  end

  def expect_no_compliance_text
    page.assert_no_selector(".qs-stats__gkv")
  end
end

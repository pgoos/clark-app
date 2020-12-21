require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RetirementJourneyGavPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_gav = "/#{locale}/app/manager/retirements/gav"
    @emberHelper = EmberHelper.new
  end

  def visit_page
    visit @path_to_gav
    page.assert_current_path("/#{locale}/app/manager/retirements/gav")
  end

  def shows_correct_page_elements
    expect(page).to have_content('Gesetzliche Altersvorsorge')
    logo_wrapper = page.find('.manager__retirement__gav__top-section__right')
    expect(logo_wrapper).to have_selector('img')
    page.assert_selector('.manager__retirement__gav__middle-section__text');
  end

  def expect_progress_bar_to_reflect_journey_step(step)
    percentage = (((step-1)/3.to_f) * 100).round
    progress_bar = page.find('.progress-bar__bar', visible: :all)
    search_string = "width: #{percentage.to_s}%"
    expect(progress_bar[:style]).to include(search_string)
  end

  def has_working_back_button
    page.find('.btn-back-split').click
    page.assert_current_path("/#{locale}/app/manager")
  end

  def expect_to_see_uploaded_documents
    page.assert_selector('.manager__product__details__documents__list__item__link')
  end

  def expect_document_to_have_correct_name(name)
    page.find('.manager__product__details__documents__list__item__details__name').assert_text(name)
  end

  def use_upload_modal
    page.assert_selector('.manager__retirement__gav__middle-section__doc-upload')
    page.find('.manager__retirement__gav__middle-section__doc-upload').click
    modal = page.find('.ember-modal__body')
    expect(modal).to have_css(".manager__inquiry__document-uplaod-modal__title", :text => "Hinweise für einen erfolgreichen Dokument-Upload")
    expect(modal).to have_css(".manager__inquiry__document-uplaod-modal__heading", :text => "Bitte stelle sicher, dass Vorder- und Rückseite gut sichtbar sind und das Dokument nicht älter als ein Jahr ist.")
    expect(modal).to have_css("li", :text => "Versicherungsart")
    expect(modal).to have_css("li", :text => "Garantiertes Renteneinkommen")
    expect(modal).to have_css("li", :text => "Überschusseinkommen")
    expect(modal).to have_css("li", :text => "Rentenbeginn")
    expect(modal).to have_selector(:css, "i.ember-modal__body__close svg")
    expect(modal).to have_css(".ember-modal__body__footer__cta", :text => "OK")
    modal.find('.ember-modal__body__close').click
  end

  def click_abbrechen_cta
    page.find('.btn-next-split').click
    page.assert_current_path("/#{locale}/app/manager/retirements/pab")
  end

end
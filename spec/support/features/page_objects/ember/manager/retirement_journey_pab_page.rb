require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class RetirementJourneyPabPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_pab = "/#{locale}/app/manager/retirements/pab"
    @emberHelper = EmberHelper.new
  end

  def visit_page
    visit @path_to_pab
    page.assert_current_path(@path_to_pab)
  end

  def has_correct_elements
    expect(page).to have_css('.manager__retirement__pab__top-section__left__detail', :text => "Freiwillige Rentenversicherung")
    expect(page).to have_content('Lade deine Renteninformation hoch')
    expect(page).to have_content("Um dein Renteneinkommen zu berechnen, benötigen wir eine Standmitteilung, einen Vertragsauszug oder eine Police.")
    page.assert_selector('.manager__retirement__gav__middle-section__doc-upload')
  end

  def expect_progress_bar_to_reflect_journey_step(step)
    percentage = (((step-1)/3.to_f) * 100).round
    progress_bar = page.find('.progress-bar__bar', visible: :all)
    search_string = "width: #{percentage.to_s}%"
    expect(progress_bar[:style]).to include(search_string)
  end

  def has_working_back_button
    page.find('.btn-back-split').click
    page.assert_current_path("/#{locale}/app/manager/retirements/gav")
  end

  def open_upload_modal
    page.assert_selector('.manager__retirement__gav__middle-section__doc-upload')
    page.find('.manager__retirement__gav__middle-section__doc-upload').click
    modal = page.find('.ember-modal__body')
    modal.find('.ember-modal__body__close').click
  end

  def expect_no_uploaded_documents
    page.assert_no_selector('.manager__product__details__documents__list__item__link')
  end

  def click_abbrechen_cta
    page.find('.btn-next-split').click
    page.assert_current_path("/#{locale}/app/manager/retirements/equity")
  end

end
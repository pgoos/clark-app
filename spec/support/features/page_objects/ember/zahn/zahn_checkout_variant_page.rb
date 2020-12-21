require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class ZahnCheckoutVariantPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/zahnzusatz/variantc/calculations?option=payback"
    @path_to_profiling = "/#{locale}/app/zahnzusatz/variantc/profiling"
    @path_to_confirmation = "/#{locale}/app/zahnzusatz/confirmation"
    @path_to_homepage = "/#{locale}/"
    @emberHelper = EmberHelper.new
  end


  def visit_page
    sleep 3 # Adding the sleep because the page takes time to load, and the spec becomes flaky
    visit @path_to_page
    page.assert_current_path(@path_to_page)
  end

  def expect_profiling_page
    page.assert_current_path(/zahnzusatz\/variantc\/profiling/)
  end

  def visit_confirmation_page
    visit @path_to_confirmation
    page.assert_current_path(@path_to_confirmation)
  end

  def expect_homepage
    page.assert_current_path(@path_to_homepage)
  end

  def calculations_page_has_correct_elements
    # calculations page test
    page.assert_selector('.zahn-calculation__top-section')
    page.assert_selector('.zahn-calculation__tarif-section__list')
    card = first('.zahn-calculation__tarif-section__list__list-item')
    card.assert_selector('.zahn-calculation__tarif-section__incentive')
    card.assert_selector('.zahn-calculation__tarif-section__top-section')
    card.assert_selector('.btn')
    find('.form-list__item__input').set('23')
    card.find('.btn').click

  end

  def profiling_page_has_correct_elements
    #profiling page test
    page.assert_selector('.zahn-profiling__top-heading')
    find('#text-field-email').set('email@email.com')
    find('.datepicker-input').set('09.08.1994')
    find('#text-field-first-name').set('firstName')
    find('#text-field-last-name').set('lastName')
    find('#text-field-city').set('city')
    find('#text-field-postal-code').set('666666')
    find('#text-field-street').set('street')
    find('#text-field-house-num').set('455')
    find('#text-field-iban').set('DE89 3704 0044 0532 0130 00')

    find('label[for=zahnProfilingCheck]').click
    find('label[for=legalOneCheck]').click
    find('label[for=legalTwoCheck').click
    find('label[for=legalThreeCheck').click
    find('label[for=legalFourCheck').click

    find('.btn-primary').click
  end

  def confirming_page_has_correct_elements
    find('.zahn-confirmation__top-heading')
    find('.zahn-confirmation__detail-section')
    find('.zahn-confirmation__detail-section__confirmation-section--left-section')
    find('.zahn-confirmation__detail-section__confirmation-section--right-section')
    find('.btn-primary').click
  end
end

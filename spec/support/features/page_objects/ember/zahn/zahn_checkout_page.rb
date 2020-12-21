require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class ZahnCheckoutPage < PageObject

  include FeatureHelpers


  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/zahnzusatz/profiling"
    @emberHelper = EmberHelper.new
  end


  def visit_page
    visit @path_to_page
  end


  def profiling_page_visited
    page.assert_selector('.zahn-profiling__top-heading', visible: true)
  end


  def fill_profiling_page_with_data
    find("#text-field-first-name").set('firstName')
    find("#text-field-last-name").set('lastName')
    find("#text-field-email").set('lastName')
    find("#text-field-postal-code").set('666666')
    find("#text-field-city").set('city')
    find("#text-field-street").set('street')
    find("#text-field-house-num").set('455')
    find("#mandate_birthdate").set('21.06.1990')
    find("#text-field-iban").set('LI21 0881 0000 2324 013A A')
    find(".legal-check0").click()
    find(".legal-check1").click()
    find(".legal-check2").click()
    find(".legal-check3").click()
    find(".legal-check4").click()
  end


  def submit_and_move_to_confirmation
    find(".btn-primary").click()
    # @emberHelper.wait_for_ember_transition
    # expect(current_path).to eq("/#{I18n.locale}/app/zahnzusatz/confirmation")
  end

end

require 'rails_helper'
require './spec/support/features/page_objects/ember/zahn/zahn_checkout_variant_page'

RSpec.describe "ZahnCheckout", :browser, type: :feature, js: true, skip: true do
  let(:locale) { I18n.locale }
  let(:zahn_checkout_page) { ZahnCheckoutVariantPage.new }
  let(:lead) { create(:lead, confirmed_at: DateTime.now, mandate: create(:mandate)) }
  context 'visit the landing page' do
    before do
      login_as(lead, scope: :lead)
      zahn_checkout_page.visit_page
    end

    it 'should go to the calculation page and go through the journey' do
      zahn_checkout_page.calculations_page_has_correct_elements
      zahn_checkout_page.expect_profiling_page
      zahn_checkout_page.profiling_page_has_correct_elements
      # zahn_checkout_page.visit_confirmation_page
      # zahn_checkout_page.confirming_page_has_correct_elements
    end
  end
end

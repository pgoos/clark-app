require 'rails_helper'
require './spec/support/features/page_objects/ember/zahn/zahn_checkout_page'

RSpec.describe "ZahnCheckout", :timeout, :slow, :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:zahn_checkout_page) { ZahnCheckoutPage.new }

  context 'visit the landing page' do
    before do
      zahn_checkout_page.visit_page
    end

    it 'should go to the profiling page and go through the journey', skip: "excluded from nightly, review" do
      zahn_checkout_page.profiling_page_visited
      zahn_checkout_page.fill_profiling_page_with_data
      zahn_checkout_page.submit_and_move_to_confirmation
      # The test are incomplete due to problems with checkboxes!!!
    end
  end
end

require 'rails_helper'
require './spec/support/features/page_objects/ember/iban/iban_offer_page'

RSpec.describe 'Iban offer page', :timeout, :slow, :browser, type: :feature, js: true do

  let(:locale) { I18n.locale }
  let!(:user) { create(:user, confirmed_at: DateTime.now, mandate: create(:mandate)) }
  let(:page_object) { IbanOfferPage.new }
  # Create a offer for a user, login as them and go to iban page
  let!(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }


  describe 'page and form interaction' do
    before(:each) do
      login_as(user, scope: :user)
      page_object.navigate(opportunity.offer.id)
    end

    it 'should enable the next button when there is content in the IBAN number input' do
      page_object.clear_form
      page_object.fill_in_iban('something')
      expect(page).not_to have_selector('.btn-primary[disabled]')
    end

    it 'should require a valid IBAN number', skip: 'This has issues with the observer on the input' do
      page_object.clear_form
      # Invalid IBAN number in the republik of Gareth Fuller
      page_object.fill_in_iban('SOMETHING WRONG')
      find('.btn-primary').click
      page_object.expect_iban_error
    end

  end

  describe 'when in the context of an offer', :clark_context, skip: "bacsue of observeres also does not work without selenium" do

    before(:each) do
      # Set the category simple checkout flag so we get the iban form
      opportunity.category.update_attributes(simple_checkout: true)

      login_as(user, :scope => :user)

      page_object.navigate_checkout(opportunity.offer.id, opportunity.offer.offer_options.first.id)
      page_object.wait_for_page
      # Click the primarry button on the checkout page
      page_object.navigate_click('.btn-primary', "offer/#{opportunity.offer.id}/iban")
    end

    it 'should allow a valid IBAN number when coming from an offer view' do
      page_object.clear_form
      # Valid IBAN
      page_object.fill_in_iban('GB32ESSE40486562136016')
      page_object.submit_form
      page_object.expect_offer_confirmation
    end

  end

  describe 'page validation logic' do

    it 'redirects to the login page if you do not have a mandate' do
      page_object.navigate(opportunity.offer.id)
      page_object.wait_for_page
      page_object.expect_login_page
    end

    it 'redirects if you dont have access to the offer ID you are requesting' do
      login_as(user, scope: :user)
      page_object.navigate(23442)
      page_object.wait_for_page
      page_object.expect_manager_page
    end
  end

end

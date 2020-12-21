require 'rails_helper'

feature 'Request app link on the homepage',  :browser, type: :feature, js: true, skip: "The snippet is currently not in the homepage" do

  let(:locale) { I18n.locale }

  # Some selectors for the tests
  confimed = '.request-app-link__confirmed'
  unconfirmed = '.request-app-link__unconfirmed'
  input = 'contact_details'
  cta = '.request-app-link__cta'

  before(:each) do
    I18n.locale = :de
    visit root_path(locale: :locale)
  end

  context 'Validating input' do


    it 'should validate as a phone number if no @ sign' do
      fill_in(input, :with => 'thisissomestring')
      find(cta).click
      expect(page).to have_content(I18n.t('validation.phone.invalid'))
    end

    it 'should accept a valid phone number' do
      fill_in(input, :with => '0090299930')
      find(cta).click
      expect(page).not_to have_content(I18n.t('validation.phone.invalid'))
      page.assert_selector(confimed, visible: true)
    end

    it 'should validate as an email if an @ sign provided' do
      fill_in(input, :with => '@something')
      find(cta).click
      expect(page).to have_content(I18n.t('validation.email.invalid'))
    end

    it 'should accept a valid email' do
      fill_in(input, :with => 'something@good.com')
      find(cta).click
      expect(page).not_to have_content(I18n.t('validation.email.invalid'))
      page.assert_selector(confimed, visible: true)
    end

  end

  context 'Showing the confirmation message' do

    it 'should not show the confirmation message if invalid' do
      fill_in(input, :with => 'this is invalid')
      find(cta).click
      page.assert_selector(unconfirmed, visible: true)
    end

    it 'should show the confirmation message and not the form if valid' do
      fill_in(input, :with => 'thisis@invalid.com')
      find(cta).click
      page.assert_selector(confimed, visible: true)
    end

  end


end

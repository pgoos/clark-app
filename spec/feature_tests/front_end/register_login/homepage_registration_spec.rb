require 'rails_helper'
require './spec/support/features/page_objects/home_page'

RSpec.describe 'Register homepage snippet', :browser, type: :feature, js: true, skip: "The snippet is currently not in the homepage" do
  let(:locale) { I18n.locale }
  let(:home) { HomePage.new }

  before do
    I18n.locale = :de
  end

  it 'should redirect only when password is correct' do
    home.navigate_home

    within(:css, '.homepage_registration') do
      fill_in 'user_email', with: 'example.com'
      fill_in 'user_password', with: '1234'

      expect do
        click_button I18n.t('signup_email')
      end.to change { current_path }.to( '/de/signup')
    end

    within(:css, '.register_user') do
      fill_in 'user_email', with: 'tester@example.com'
      fill_in 'user_password', with: 'BlaBla1234'

      expect do
        click_button I18n.t('signup_email')
      end.to change { current_path }.to( '/de/app/mandate' )
    end
  end
end

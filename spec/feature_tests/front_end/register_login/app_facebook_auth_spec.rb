require 'rails_helper'

feature 'on the clark app the facebook button should trigger a native api call and not open facebook page', :slow, :browser, js: true do

  using_clark_app do
    scenario 'on register page', skip: "excluded from nightly, review" do
      visit new_user_registration_path(locale: locale, next_user_path: edit_account_user_path)

      expect {
        click_link I18n.t('register_with', provider: 'Facebook')
      }.to_not change { current_path }
    end

    scenario 'on login page' do
      visit new_user_session_path(locale: locale, next_user_path: edit_account_user_path)

      expect {
        click_link I18n.t('login_with', provider: 'Facebook')
      }.to_not change { current_path }
    end
  end
end

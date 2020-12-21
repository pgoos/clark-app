require 'rails_helper'

feature 'A new user should stay on current page when submitting with errors', :slow, :browser, skip: "excluded from nightly, review" do

  scenario '', :js => true do
    user = create(:user)

    visit root_path(locale: locale)

    click_link I18n.t('application.page_navigation.register')
    within(:css, '#new_user') do
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'Tot4llyN0tTheP4ssw0rd'
      #fill_in 'user_password_confirmation', with: 'Tot4llyN0tTheP4ssw0rd'

      expect do
        click_button I18n.t('signup_email')
      end.not_to change { current_path }
    end
  end
end

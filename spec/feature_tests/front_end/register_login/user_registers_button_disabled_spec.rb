require 'rails_helper'

feature 'A new user registers and the register button is disabled', :browser, :slow do

  scenario '', skip: "excluded from nightly, review" do
    visit new_user_registration_path(locale: locale)

    # check that we have the disable with data attribute set
    within '.register_user' do
      expect(find('.btn-primary')['data-disable-with']).to eq I18n.t('signup_registering')
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe "A new user registers and not confirms", :slow, :browser, skip: "excluded from nightly, review" do
  it do
    visit new_user_registration_path(locale: locale)

    fill_in "user_email", with: "user_#{SecureRandom.hex(5)}@test.clark.de"
    fill_in "user_password", with: Settings.seeds.default_password
    # fill_in 'user_password_confirmation', with: Settings.seeds.default_password

    expect(click_button(I18n.t("signup_email"))).to change { ActionMailer::Base.deliveries.count }.by(1)

    # expect(current_path).to eq(new_account_wizard_path(locale: locale))
    expect(page).to have_current_path("/#{locale}/app/mandate")
  end
end

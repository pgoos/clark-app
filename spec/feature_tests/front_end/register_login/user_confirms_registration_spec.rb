# frozen_string_literal: true

require "rails_helper"

describe "A new user registers and confirms", :slow, :browser do
  it "", skip: "excluded from nightly, review" do
    visit new_user_registration_path(locale: locale)
    fill_in "user_email", with: Faker::Internet.email
    fill_in "user_password", with: Settings.seeds.default_password
    # fill_in 'user_password_confirmation', with: Settings.seeds.default_password

    expect {
      click_button I18n.t("signup_email")
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    last_email = ActionMailer::Base.deliveries.last.text_part.decoded
    # rubocop:disable Layout/LineLength
    match_group = last_email.scan %r{/ahoy/messages/\w{32}/click\?signature=\w{40}&url=(http%3A%2F%2Ftest.host%2Fde%2Fconfirmation%3Fconfirmation_token%3D.*%26utm_campaign%3Dconfirmation_instructions%26utm_medium%3Demail%26utm_source%3Dauthentication_mailer)}
    # rubocop:enable Layout/LineLength
    link = URI.decode match_group[0][0]
    visit link

    page.assert_current_path("/#{locale}/app/mandate")
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lead mandate wizard redirect to finished route",
               :browser, type: :feature, js: true do
  it "registers as a current_lead" do
    mandate = create(:mandate, :wizard_to_be_confirmed, phone: "+4915112345678")
    # pass all steps
    mandate.phones.update_all(verified_at: DateTime.current)
    mandate.address.update!(street: "xxx", house_number: 10, zipcode: 10_000, city: "xxx")
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.save!

    lead = create(:device_lead, mandate: mandate, devices: [create(:device)])
    login_as(lead.reload, scope: :lead)

    visit "/#{I18n.locale}/app/mandate/register"

    within(:css, ".form-list") do
      fill_in "mandate_register_email", with: "user_#{SecureRandom.hex(5)}@test.clark.de"
      fill_in "mandate_register_password", with: Settings.seeds.default_password
    end

    click_button I18n.t("signup_lead")

    expect(page).to have_selector(".mandate-finished__container")

    expect(page).to have_current_path "/#{I18n.locale}/app/mandate/finished"

    # The lead should have been deleted when converted to user
    expect(Lead.find_by(id: lead.id)).to be_blank
  end

  it "logins as a current_lead" do
    lead = create(:device_lead, mandate: create(:mandate), devices: [create(:device)])
    user = create(:user, mandate: create(:mandate))
    login_as(lead, scope: :lead)

    visit new_user_session_path(locale: I18n.locale, next_user_path: edit_account_user_path)

    within(:css, "#new_user") do
      fill_in "user_email", with: user.email
      fill_in "user_password", with: user.password

      expect { click_button I18n.t("signin") }
        .to change { current_path }
        .to(edit_account_user_path(locale: I18n.locale))
    end

    # The lead should have been deleted when converted to user
    expect(Lead.where(id: lead.id).first).to be_blank
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "An admin changes the users password and they are logged out", :browser,
               type: :feature, skip: "since we are moving the profiling page out of rails" do
  let(:user) { create(:user, mandate: create(:mandate)) }

  before do
    login_as(user, scope: :user)
    visit "/#{I18n.locale}/app/mandate/profiling"
  end

  it "logs the user out when the password is changed" do
    expect(page).to have_current_path("/#{I18n.locale}/app/mandate/profiling")

    user.update(password: Settings.seeds.default_password)

    visit "/#{I18n.locale}/app/mandate/profiling"

    expect(page).to have_current_path("/#{I18n.locale}/login")
  end
end

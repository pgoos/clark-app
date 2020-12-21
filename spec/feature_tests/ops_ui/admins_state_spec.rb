# frozen_string_literal: true

require "rails_helper"

describe "Admin state management", :slow, :browser, :integration do
  let(:resource) {
    create(:admin,
           email: "index_admin@test.clark.de",
           password: Settings.seeds.default_password,
           role: create(:role))
  }

  before do
    login_super_admin
  end

  describe "The admin activates and deactivates another admin" do
    it "deactivates and activates an admin" do
      visit_show_path(:admin, resource)
      states_are_changed(Admin,
                         deactivate: I18n.t("activerecord.state_machines.events.deactivate"),
                         activate: I18n.t("activerecord.state_machines.events.activate"))
    end
  end
end

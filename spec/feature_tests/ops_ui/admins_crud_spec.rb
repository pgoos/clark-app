# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin management", :slow, :browser, type: :feature do
  context "when a permitted admin is logged in" do
    let(:resource) {
      create(:admin,
             email: "index_admin@test.clark.de",
             password: Settings.seeds.default_password,
             role: create(:role))
    }

    before do
      login_super_admin
    end

    it "creates a new admin" do
      visit_new_path(:admin)
      i_select_options(admin_role_id: "SuperAdmin")
      i_fill_in_text_fields(admin_email: "new_admin@test.clark.de",
                            admin_password: Settings.seeds.default_password,
                            admin_password_confirmation: Settings.seeds.default_password)
      a_resource_is_created(Admin)
      i_see_text_fields(["new_admin@test.clark.de", I18n.t("activerecord.state_machines.states.active")],
                        find(".center-column-content"))
    end

    it "sees a list of admins on the index page" do
      resource
      visit_index_path(:admins)
      i_see_text_fields([resource.email,
                         I18n.t("activerecord.state_machines.states.active"),
                         I18n.l(resource.created_at, format: :number)])
    end

    it "updates an admin" do
      visit_edit_path(:admin, resource)
      i_select_options(admin_role_id: "SuperAdmin")
      i_fill_in_text_fields(admin_email: "admin3@test.clark.de",
                            admin_password: Settings.seeds.default_password,
                            admin_password_confirmation: Settings.seeds.default_password)
      a_resource_is_updated(Admin)
      i_see_text_fields(["admin3@test.clark.de",
                         I18n.t("activerecord.state_machines.states.active"),
                         I18n.l(resource.created_at, format: :number),
                         "SuperAdmin"])
    end
  end
end

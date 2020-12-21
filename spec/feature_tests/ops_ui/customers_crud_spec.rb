# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customer management", :browser, type: :feature do
  context "when a permitted admin is logged in" do
    before do
      I18n.locale = :de
      login_super_admin
    end

    let!(:resource) { create(:user) }

    let(:fill_ins) do
      {
        user_email: "test.user@test.clark.de",
        user_password: Settings.seeds.default_password,
        user_password_confirmation: Settings.seeds.default_password,
        user_mandate_attributes_first_name: "Ed",
        user_mandate_attributes_last_name: "Buck",
        user_mandate_attributes_birthdate: I18n.l(50.years.ago, format: "%Y-%m-%d")
      }
    end

    let(:selects) do
      {
        user_mandate_attributes_gender: I18n.t("attribute_domains.gender.male"),
        user_mandate_attributes_preferred_locale: "de"
      }
    end

    it "creates a new user account with mandate" do
      visit_new_path(:user)
      i_select_options(selects)
      i_fill_in_text_fields(fill_ins)
      a_resource_is_created(User)
      i_see_text_fields(
        [
          fill_ins[:user_email],
          fill_ins[:user_mandate_attributes_first_name],
          fill_ins[:user_mandate_attributes_last_name],
          I18n.l(50.years.ago, format: :date),
          selects[:user_mandate_attributes_preferred_locale],
          selects[:user_mandate_attributes_gender]
        ]
      )
    end

    it "sees a list of all user accounts" do
      visit_index_path(:users)
      i_see_text_fields([resource.email,
                         I18n.t("activerecord.state_machines.states.active"),
                         I18n.l(resource.created_at, format: :number)])
    end

    it "updates an existing user account" do
      visit_edit_path(:user, resource)
      i_select_options(selects)
      i_fill_in_text_fields(fill_ins)
      a_resource_is_updated(User)
      i_see_text_fields([
                          fill_ins[:user_mandate_attributes_first_name],
                          fill_ins[:user_mandate_attributes_last_name],
                          I18n.l(50.years.ago, format: :date),
                          selects[:user_mandate_attributes_gender]
                        ])
    end

    it "deletes an existing user account" do
      visit_index_path(:users)
      a_resource_is_deleted(User, delete_path(:user, resource))
    end
  end
end

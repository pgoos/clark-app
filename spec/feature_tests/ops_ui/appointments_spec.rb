# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Category management", :slow, :browser, type: :feature do
  context "when a permitted admin is logged in" do
    before do
      login_super_admin
    end

    context "when appointment contains 'phone' merhod_of_contact" do
      let!(:appointment) do
        create(
          :appointment,
          method_of_contact: "phone"
        )
      end

      it "admin sees uhrseit field" do
        visit_index_path(:appointments)
        i_see_text_fields(%w[Telefon Datum])
      end
    end

    context "when appointment contains 'email' merhod_of_contact" do
      let!(:appointment) do
        create(
          :appointment,
          method_of_contact: "email"
        )
      end

      it "admin doesn't see uhrseit field" do
        visit_index_path(:appointments)
        i_see_text_fields(["email"])
        i_see_no_text_fields(["Datum"])
      end
    end
  end
end

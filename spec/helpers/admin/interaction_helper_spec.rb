# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::InteractionHelper, type: :helper do
  describe "#interaction_admin_name" do
    context "interaction has associated admin" do
      it "returns admin name" do
        consultant = create(:admin, first_name: Faker::Name.first_name, last_name: Faker::Name.first_name)
        interaction = create(:interaction, admin: consultant)

        expect(interaction_admin_name(interaction)).to eql(consultant.name)
      end
    end

    context "interaction has no associated admin" do
      it "returns admin proxy name" do
        interaction = create(:interaction, admin: nil)

        expect(interaction_admin_name(interaction)).to eql(I18n.t("admin.interactions.proxy_name"))
      end
    end
  end
end

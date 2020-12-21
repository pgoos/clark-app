# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Admins::ValidateRoleChange, :integration do
  describe "#valid" do
    let(:current_admin) do
      create(:admin, role: current_role)
    end

    let(:affected_admin) do
      create(:admin, role: affected_role)
    end

    let(:current_role) do
      create(:role, weight: current_role_weight)
    end

    let(:affected_role) do
      create(:role, weight: affected_role_weight)
    end

    let(:validator) do
      described_class.new(
        current_admin: current_admin,
        affected_admin: affected_admin,
        role_id: affected_role.id
      )
    end

    context "when role_id is empty" do
      let(:validator) do
        described_class.new(
          current_admin: build(:admin),
          affected_admin: build(:admin),
          role_id: role_id_value
        )
      end

      context "with role_id = nil" do
        let(:role_id_value) { nil }

        it "returns true" do
          expect(validator).to be_valid
        end
      end

      context "with role_id is empty" do
        let(:role_id_value) { "" }

        it "returns true" do
          expect(validator).to be_valid
        end
      end
    end

    context "when curent admin has role weight less than requested" do
      let(:current_role_weight) { 5 }
      let(:affected_role_weight) { 10 }

      it "returns false" do
        expect(validator).not_to be_valid

        expect(affected_admin.errors[:role_id]).to(
          include(I18n.t("activerecord.errors.models.admin.attributes.role_id.not_allowed"))
        )
      end
    end

    context "when curent admin has role weight equal to requested" do
      let(:current_role_weight) { 5 }
      let(:affected_role_weight) { 5 }

      it "returns true" do
        expect(validator).to be_valid
      end
    end

    context "when curent admin has role weight greater than requested" do
      let(:current_role_weight) { 5 }
      let(:affected_role_weight) { 3 }

      it "returns true" do
        expect(validator).to be_valid
      end
    end
  end
end

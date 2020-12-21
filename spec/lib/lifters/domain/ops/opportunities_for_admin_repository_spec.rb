# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Ops::OpportunitiesForAdminRepository, :integration do
  let(:admin) { create(:admin) }
  let(:adminB) { create(:admin) }
  let(:active_mandate) { create(:mandate) }
  let(:revoked_mandate) { create(:mandate, :revoked) }
  let(:permission_for_revoked_mandates) { create(:permission, :view_revoked_mandates) }

  context "when multiple opportunities for different admins exists" do
    let!(:offered_opportunity_for_admin) do
      create(:opportunity, :offer_phase, mandate: active_mandate, admin: admin)
    end
    let!(:opportunity_in_created_state_for_adminB) do
      create(:opportunity, :created, mandate: active_mandate, admin: adminB)
    end
    let!(:offered_opportunity_for_adminB) do
      create(:opportunity, :offer_phase, mandate: active_mandate, admin: adminB)
    end

    context "when called repo with adminB" do
      it "shows opportunity in offered state assigned to adminB" do
        opportunities = described_class.call(adminB).pluck(:id)

        expect(opportunities).to match_array([offered_opportunity_for_adminB.id])
      end
    end
  end

  context "when Opportunity for revoked_mandate exists" do
    let!(:opportunity_for_active_mandate) do
      create(:opportunity, :offer_phase, mandate: active_mandate, admin: admin)
    end
    let!(:opportunity_for_revoked_mandate) do
      create(:opportunity, :offer_phase, :skip_validations, mandate: revoked_mandate, admin: admin)
    end

    context "when admin does not have permission to view revoked mandate" do
      it "does not return revoked mandate" do
        expect(
          described_class.call(admin).pluck(:id)
        ).to match_array([opportunity_for_active_mandate.id])
      end
    end

    context "when admin does have permission to view revoked mandate" do
      before do
        admin.permissions << permission_for_revoked_mandates
      end

      it "return all mandates including revoked" do
        expect(
          described_class.call(admin).pluck(:id)
        ).to match_array([opportunity_for_revoked_mandate.id, opportunity_for_active_mandate.id])
      end
    end
  end
end

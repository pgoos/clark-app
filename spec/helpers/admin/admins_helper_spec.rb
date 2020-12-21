# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdminsHelper, type: :helper do
  let(:admin) { create :admin, role: role }

  describe "#owner_ident_allowed_for_admin" do
    context "owner_ident is clark" do
      context "role has authorization" do
        let(:role) { create(:role, scope_authorizations: [scope_authorization]) }
        let!(:scope_authorization) { create(:scope_authorization, :mandates_owner, value: "clark") }

        it "should return clark ident" do
          expect(helper.owner_ident_allowed_for(role)).to include("clark")
        end
      end

      context "role doesn't have authorization" do
        let(:role) { create(:role) }

        it "should not return clark ident" do
          expect(helper.owner_ident_allowed_for(role)).to eq([])
        end
      end
    end

    context "owner_ident is from partners" do
      context "partner is active" do
        let(:partner) { create :partner, :active }

        context "role has authorization" do
          let(:role) { create(:role, scope_authorizations: [scope_authorization]) }
          let!(:scope_authorization) { create(:scope_authorization, :mandates_owner, value: partner.ident) }

          it "should return partner ident" do
            expect(helper.owner_ident_allowed_for(role)).to include(partner.ident)
          end
        end

        context "role doesn't have authorization" do
          let(:role) { create(:role) }

          it "should not return partner ident" do
            expect(helper.owner_ident_allowed_for(role)).not_to include(partner.ident)
          end
        end
      end

      context "partner is inactive" do
        let(:partner) { create :partner, :inactive }

        context "role has authorization" do
          let(:role) { create(:role, scope_authorizations: [scope_authorization]) }
          let!(:scope_authorization) { create(:scope_authorization, :mandates_owner, value: partner.ident) }

          it "should not return partner ident" do
            expect(helper.owner_ident_allowed_for(role)).not_to include(partner.ident)
          end
        end

        context "role doesn't have authorization" do
          let(:role) { create(:role) }

          it "should not return partner ident" do
            expect(helper.owner_ident_allowed_for(role)).not_to include(partner.ident)
          end
        end
      end
    end
  end
end

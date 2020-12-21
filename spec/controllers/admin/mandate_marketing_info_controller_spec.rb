# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MandateMarketingInfoController, :integration, type: :controller do
  let(:role)    { create(:role, permissions: Permission.where(controller: "admin/mandate_marketing_info")) }
  let(:admin)   { create(:admin, role: role) }
  let(:mandate) { create :mandate, user: user }
  let(:user)    { create :user, source_data: source_data }

  let(:source_data) do
    {adjust: {network: "USER_NETWORK", campaign: "USER_CAMPAIGN"}, partner_customer_id: "PC_ID"}
  end

  before { login_admin(admin) }

  describe "GET edit" do
    before do
      get :edit, params: {id: mandate.id, locale: :de}
    end

    it "responds with success" do
      expect(response.status).to eq 200
    end
  end

  describe "PATCH /update" do
    let(:mandate_params) do
      {
        network: "NEW_NET", source_campaign: "NEW_CAMP", utm_term: "NEW_TERM",
        utm_content: "NEW_CONTENT", utm_medium: "NEW_MEDIUM", partner_customer_id: "NEW_PC_ID"
      }
    end
    let(:expected_response) do
      {
        "adjust" => {"network" => "NEW_NET", "campaign" => "NEW_CAMP",
                     "adgroup" => "NEW_CONTENT", "creative" => "NEW_TERM",
                     "medium" => "NEW_MEDIUM"},
        "partner_customer_id" => "NEW_PC_ID"
      }
    end

    before { patch :update, params: {id: mandate.id, mandate: mandate_params, locale: :de} }

    it { is_expected.to redirect_to(admin_mandate_path) }

    it "updates mandate user or lead" do
      expect(user.reload.source_data).to eq expected_response
    end

    it "doesn not update the ident" do
      expect(user.reload.mandate.owner_ident).to eq("clark")
    end

    describe "when network is malburg ident is updated" do
      before do
        mandate_params[:network] = "malburg"
        patch :update, params: {id: mandate.id, mandate: mandate_params, locale: :de}
      end

      it "updates the owner ident to malburg if network is malburg" do
        expect(user.reload.mandate.owner_ident).to eq("malburg")
      end
    end
  end
end

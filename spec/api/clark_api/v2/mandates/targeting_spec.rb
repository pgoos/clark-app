# frozen_string_literal: true
require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates::Targeting, :integration do
  context "PATCH /api/mandates/:id/targeting" do
    let(:user) { create(:user, mandate: create(:mandate)) }
    let(:lead) { create(:lead, mandate: create(:mandate)) }

    it "sets the mandates wizard step to targeting as a user" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}/targeting"

      expect(response.status).to eq(200)
      expect(Mandate.find(user.mandate.id).current_wizard_step).to eq("targeting")
    end

    it "sets the mandates wizard step to targeting  as a lead" do
      login_as(lead, scope: :lead)

      json_patch_v2 "/api/mandates/#{lead.mandate.id}/targeting"

      expect(response.status).to eq(200)
      expect(Mandate.find(lead.mandate.id).current_wizard_step).to eq("targeting")
    end

    it "errors when the mandate id does not match" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/0/targeting"

      expect(response.status).to eq(404)
      expect(Mandate.find(user.mandate.id).current_wizard_step).not_to eq("targeting")
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/mandates/#{user.mandate.id}/targeting"
      expect(response.status).to eq(401)
    end
  end
end

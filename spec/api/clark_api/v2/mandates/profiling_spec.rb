# frozen_string_literal: true
require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates::Profiling, :integration do
  context "PATCH /api/mandates/:id/profiling" do
    let(:user) { create(:user, mandate: create(:mandate)) }
    let(:lead) { create(:lead, mandate: create(:mandate)) }

    it "sets the mandates wizard step to profiling as a user" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}/profiling"

      expect(response.status).to eq(200)
      expect(Mandate.find(user.mandate.id).current_wizard_step).to eq("profiling")
    end

    it "sets the mandates wizard step to profiling as a lead" do
      login_as(lead, scope: :lead)

      json_patch_v2 "/api/mandates/#{lead.mandate.id}/profiling"

      expect(response.status).to eq(200)
      expect(Mandate.find(lead.mandate.id).current_wizard_step).to eq("profiling")
    end

    it "errors when the mandate id does not match" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/0/profiling"

      expect(response.status).to eq(404)
      expect(Mandate.find(user.mandate.id).current_wizard_step).not_to eq("profiling")
    end

    it "errors when not all required fields are set" do
      address = build(:address, city: nil)
      mandate = create(:wizard_targeted_mandate, active_address: address)
      user    = create(:user, mandate: mandate)

      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}/profiling"

      expect(response.status).to eq(400)
      expect(Mandate.find(user.mandate.id).current_wizard_step).not_to eq("profiling")
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/mandates/#{user.mandate.id}/profiling"
      expect(response.status).to eq(401)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates::Confirming, :integration do
  context "PATCH /api/mandates/:id/confirming" do
    let(:user) { create(:user, mandate: create(:mandate)) }
    let(:lead) { create(:lead, mandate: create(:mandate)) }

    it "sets the mandates wizard step to confirming as a user" do
      user = create(:user, mandate: create(:signed_unconfirmed_mandate))
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}/confirming"
      mandate = Mandate.find(user.mandate.id)

      expect(response.status).to eq(200)
      expect(mandate.current_wizard_step).to eq("confirming")
      expect(mandate.tos_accepted_at).not_to eq(nil)
      expect(mandate.confirmed_at).not_to eq(nil)
    end

    it "should update mandate's info column" do
      user = create(:user, mandate: create(:signed_unconfirmed_mandate))
      login_as(user, scope: :user)

      info_param = {
        incentive_funnel_consent: true,
        incentive_funnel_condition: true
      }

      json_patch_v2 "/api/mandates/#{user.mandate.id}/confirming", info: info_param
      mandate = Mandate.find(user.mandate.id)

      expect(response.status).to eq(200)
      expect(mandate.incentive_funnel_consent).to eq(true)
      expect(mandate.incentive_funnel_condition).to eq(true)
    end

    it "sets the mandates wizard step to confirming as a lead" do
      lead = create(:lead, mandate: create(:signed_unconfirmed_mandate))
      login_as(lead, scope: :lead)

      json_patch_v2 "/api/mandates/#{lead.mandate.id}/confirming"
      mandate = Mandate.find(lead.mandate.id)

      expect(response.status).to eq(200)
      expect(mandate.current_wizard_step).to eq("confirming")
      expect(mandate.tos_accepted_at.to_datetime).not_to eq(nil)
      expect(mandate.confirmed_at.to_datetime).not_to eq(nil)
    end

    it "adds missing steps to wizard when some of them are not performed" do
      create(:signature, signable: user.mandate)
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}/confirming"

      expect(response.status).to eq(200)
      expect(Mandate.find(user.mandate.id).wizard_steps)
        .to eq %w[targeting profiling confirming]
    end

    it "errors when the mandate id does not match" do
      create(:signature, signable: user.mandate)
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/0/confirming"

      expect(response.status).to eq(404)
      expect(Mandate.find(user.mandate.id).current_wizard_step).not_to eq("confirming")
    end

    it "returns 401 if the user is not singed in" do
      user = create(:user, mandate: create(:signed_unconfirmed_mandate))
      json_patch_v2 "/api/mandates/#{user.mandate.id}/confirming"
      expect(response.status).to eq(401)
    end

    context "when the customer is home24 source" do
      let(:home24_mandate) { create(:signed_unconfirmed_mandate, :home24) }
      let(:info_param) {
        { home24_contract_details_condition: true, home24_consultation_waiving_condition: true }
      }

      it "should call the interactor to save conditions for customer" do
        login_as(home24_mandate.user, scope: :user)

        json_patch_v2 "/api/mandates/#{home24_mandate.id}/confirming", info: info_param
        mandate = Mandate.find(home24_mandate.id)
        home24_conditions = mandate.info["home24_conditions"]

        expect(response.status).to eq(200)
        expect(home24_conditions["contract_details"]).to eq(true)
        expect(home24_conditions["consultation_waiving"]).to eq(true)
      end
    end
  end
end

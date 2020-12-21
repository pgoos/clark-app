# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::OfferAutomations::Questionnaires, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  let(:category) { create(:category) }
  let(:questionnaire) do
    create(
      :questionnaire,
      category: category
    )
  end
  let(:automation) { create(:offer_automation, questionnaire: questionnaire) }

  describe "when authenticated" do
    before do
      login_as(admin, scope: :admin)
    end

    it "should deliver the automation's questionnaire" do
      json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/questionnaire"
      expect_ok
      expect(json_response.questionnaire.identifier).to eq(questionnaire.identifier)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::Exploration, :integration, :vcr, type: :request do
  describe "GET /api/customer/exploration/contract_overview_eligible" do
    context "when user is not logged in" do
      it "returns 401" do
        json_get_v5 "/api/customer/exploration/contract_overview_eligible"
        expect(response.status).to eq 401
      end
    end

    context "when user is logged in" do
      let(:mandate) { create(:mandate) }
      let(:user) { create(:user, mandate: mandate) }

      before { login_as(user, scope: :user) }

      context "when user is eligible to display contract overview screen" do
        let!(:product) { create(:product, mandate: mandate, analysis_state: "details_missing") }

        it "returns information that user is eligible" do
          json_get_v5 "/api/customer/exploration/contract_overview_eligible"
          expect(response.status).to eq 200
          expect(json_response["eligible"]).to eq true
        end
      end

      context "when user is not eligible to display contract overview screen" do
        it "returns information that user is not eligible" do
          json_get_v5 "/api/customer/exploration/contract_overview_eligible"
          expect(response.status).to eq 200
          expect(json_response["eligible"]).to eq false
        end
      end
    end
  end

  describe "GET /api/customer/exploration/recommendation_overview_eligible" do
    context "when user is not logged in" do
      it "returns 401" do
        json_get_v5 "/api/customer/exploration/recommendation_overview_eligible"
        expect(response.status).to eq 401
      end
    end

    context "when user is logged in" do
      let(:mandate) { create(:mandate) }
      let(:user) { create(:user, mandate: mandate) }

      before { login_as(user, scope: :user) }

      context "when user is eligible to display recommendation overview screen" do
        let!(:questionnaire) { create(:bedarfscheck_questionnaire) }
        let!(:questionnaire_response) do
          create(
            :questionnaire_response,
            mandate: mandate,
            questionnaire: questionnaire,
            state: :completed
          )
        end

        it "returns information that user is eligible" do
          json_get_v5 "/api/customer/exploration/recommendation_overview_eligible"
          expect(response.status).to eq 200
          expect(json_response["eligible"]).to eq true
        end
      end

      context "when user is not eligible to display recommendation overview screen" do
        it "returns information that user is not eligible" do
          json_get_v5 "/api/customer/exploration/recommendation_overview_eligible"
          expect(response.status).to eq 200
          expect(json_response["eligible"]).to eq false
        end
      end
    end
  end
end

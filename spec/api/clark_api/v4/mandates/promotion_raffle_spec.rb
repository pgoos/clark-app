# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V4::Mandates::TermsAcceptance, :integration do
  let(:mandate) { create :mandate }
  let(:user)    { create :user, mandate: mandate }
  let(:lead)    { create :lead, mandate: mandate }

  describe "PUT /api/mandates/:id/promotion_raffle" do
    let(:put_params) {
      {
        id: 123,
        email: "gareth-rocks@gmail.com",
        first_name: "Karl-Heinz",
        last_name: "Test",
        birthdate: 30.years.ago.strftime("%d.%m.%Y"),
        gender: "male",
        insurances: "1-2",
        promotion_identifier: "facebook",
        promotion_raffle_percentage: "to_50",
        send_email: true,
        consent: true,
        tracking: {
          utm_source: "some source",
          utm_campaign: "some campaign",
          utm_content: "some content",
          utm_term: "some term",
          utm_medium: "some medium",
          utm_landing_page: "https://www.clark.de/de/hunde-op-versicherung"
        }
      }
    }

    let(:params) { put_params }

    context "when not logged in because no user or lead found," do
      it "returns validation error 404" do
        json_put_v4 "/api/mandates/#{mandate.id}/promotion_raffle", params
        expect(response.status).to eq(404)
      end
    end

    context "when logged in as a user," do
      it_behaves_like "promotion raffle entry" do
        let(:user_resource) { user }
        let(:user_type) { :user }
      end
    end

    context "when logged in as a lead," do
      it_behaves_like "promotion raffle entry" do
        let(:user_resource) { lead }
        let(:user_type) { :lead }
      end
    end

  end
end

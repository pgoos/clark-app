# frozen_string_literal: true

require "rails_helper"

describe Customer::Api::V5::Accounts, :integration, type: :request do
  describe "PATCH /api/bi/tracking/adjust-attribution" do
    let(:params) do
      {
        adgroup: "adgroup 1",
        network: "network 2",
        campaign: "campaign 3",
        creative: "creative 4"
      }
    end

    it "updates visit" do
      json_patch_v5 "/api/bi/tracking/adjust-attribution", params
      expect(response.status).to eq 200

      visit = Tracking::Visit.last
      expect(visit.utm_content).to eq "adgroup 1"
      expect(visit.utm_source).to eq "network 2"
      expect(visit.utm_term).to eq "creative 4"
      expect(visit.utm_campaign).to eq "campaign 3"
    end

    context "with customer and without visit" do
      it "updates customer attribution and creates visit" do
        lead = create(:lead)
        login_as(lead, scope: :lead)

        json_patch_v5 "/api/bi/tracking/adjust-attribution", params
        expect(response.status).to eq 200

        visit = Tracking::Visit.last
        expect(visit.mandate_id).to eq lead.mandate_id
        expect(visit.utm_content).to eq "adgroup 1"
        expect(visit.utm_source).to eq "network 2"
        expect(visit.utm_term).to eq "creative 4"
        expect(visit.utm_campaign).to eq "campaign 3"

        lead.reload
        expect(lead.adjust["adgroup"]).to eq "adgroup 1"
        expect(lead.adjust["network"]).to eq "network 2"
        expect(lead.adjust["creative"]).to eq "creative 4"
        expect(lead.adjust["campaign"]).to eq "campaign 3"
      end
    end

    context "with customer and visit" do
      it "updates customer and lead attributions" do
        ahoy_visit = "c1b6324a-bcb4-4ce8-b44c-88493f4d912a"
        ahoy_visitor = "668337f0-8707-426b-a797-adcb5348640e"
        ahoy_cookies = { "HTTP_COOKIE" => "ahoy_visit=#{ahoy_visit}; ahoy_visitor=#{ahoy_visitor};" }

        lead = create(:lead)
        visit = create(:tracking_visit, id: ahoy_visit, visitor_id: ahoy_visitor, mandate_id: lead.mandate_id)

        login_as(lead, scope: :lead)

        json_patch_v5 "/api/bi/tracking/adjust-attribution", params, ahoy_cookies
        expect(response.status).to eq 200

        lead.reload
        visit.reload

        expect(visit.utm_content).to eq "adgroup 1"
        expect(visit.utm_source).to eq "network 2"
        expect(visit.utm_term).to eq "creative 4"
        expect(visit.utm_campaign).to eq "campaign 3"
        expect(lead.adjust["adgroup"]).to eq "adgroup 1"
        expect(lead.adjust["network"]).to eq "network 2"
        expect(lead.adjust["creative"]).to eq "creative 4"
        expect(lead.adjust["campaign"]).to eq "campaign 3"
      end
    end
  end
end

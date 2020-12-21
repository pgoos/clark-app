# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::PublicPartners::MandateEvents, :integration do
  let(:network) { "networkabc" }
  let(:partner) do
    create(:acquisition_partner, networks: [network])
  end

  let(:valid_headers) do
    {
      HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic
        .encode_credentials(partner.username, partner.password),
      HTTP_ACCEPT:        "application/vnd.clark-public_partners_v1+json"
    }
  end

  describe "GET /api/mandate_events" do
    context "user is not authenticated" do
      it "should reject not authenticated user" do
        get "/api/mandate_events"
        expect(response.status).to eq(401)
      end
    end

    context "empty data set" do
      it "should get empty mandate_events" do
        get "/api/mandate_events", headers: valid_headers
        expect(response.status).to eq(200)
        expect(response.body).to eq("{\"result\":[]}")
      end
    end

    context "has matching users and leads" do
      let(:voucher) { create(:voucher, metadata: { source: network, campaign: "test_campaign" } ) }
      let(:user) { create(:user, source_data: { adjust: { network: network } }) }
      let(:mandate) { create(:mandate, user: user, voucher: voucher) }
      let(:category) { create(:category_phv) }
      let(:plan) { create(:plan, category: category) }

      before do
        create(:category_gkv)
        create(:business_event, entity: mandate, action: "accept")
      end

      context "has no matching products" do
        it "should have an empty products array" do
          get "/api/mandate_events", headers: valid_headers
          expect(response.status).to eq(200)

          result = json_response["result"]

          expect(result.size).to eq 1
          expect(result.first["mandate_id"]).to eq mandate.id
          expect(result.first["products"]).to eq []
        end
      end

      context "has matching products" do
        let!(:product) do
          create(:product, :sold_by_others, plan: plan, mandate: mandate, state: :details_available)
        end

        it "should get mandate_events" do
          get "/api/mandate_events", headers: valid_headers
          expect(response.status).to eq(200)

          result = json_response["result"]

          expect(result.size).to eq 1
          expect(result.first["mandate_id"]).to eq mandate.id
          expect(result.first["products"].size).to eq 1
          expect(result.first["products"][0]["product_id"]).to eq product.id
        end
      end
    end
  end
end

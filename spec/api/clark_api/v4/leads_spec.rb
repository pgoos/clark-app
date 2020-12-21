# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V4::Leads, :integration do
  let(:category) { create :category }

  describe "POST /api/leads/lead_with_opportunity" do
    let(:utm_medium) { "/last-page-url"}
    let(:params) {
      {
        email: "test@gmail.com",
        first_name: "First",
        last_name: "Last",
        phone_number: ClarkFaker::PhoneNumber.phone_number,
        category_ident: category.ident,
        source_data: { anonymous_lead: true, adjust: { utm_medium: utm_medium } }
      }
    }

    context "with valid params" do
      it "should create and return the lead" do
        json_post_v4 "/api/leads/lead_with_opportunity", params
        expect(response.status).to eq(201)
        expect(json_response[:lead][:email]).to eq(params[:email])
        expect(json_response[:lead][:mandate][:first_name]).to eq(params[:first_name])
        expect(json_response[:lead][:mandate][:last_name]).to eq(params[:last_name])
        expect(json_response[:lead][:mandate][:phone]).to match(params[:phone_number])
        expect(json_response[:lead][:adjust]).to match(params[:source_data][:adjust])
      end

      it "create a opportunity for that category" do
        json_post_v4 "/api/leads/lead_with_opportunity", params
        mandate = Lead.find(json_response[:lead][:id]).mandate
        expect(mandate.opportunities.count).to eq(1)
        expect(mandate.opportunities.last.category_ident).to eq(category.ident)
        expect(mandate.opportunities.last.source_description).to eq(utm_medium)
      end

      it "merges seo_lead key as true to source_data of lead" do
        json_post_v4 "/api/leads/lead_with_opportunity", params
        lead = Lead.find(json_response[:lead][:id])
        expect(lead.source_data["seo_lead"]).to be_truthy
      end
    end

    context "no utm_medium adjust param present" do
      let(:partial_params) { params.merge(source_data: { anonymous_lead: true, adjust: {} }) }

      it "should succeed" do
        json_post_v4 "/api/leads/lead_with_opportunity", partial_params
        expect(response.status).to eq(201)
      end
    end

    context "with invalid params" do
      context "invalid category_ident" do
        let(:invalid_params) { params.merge(category_ident: "invalid") }

        it "should return status 404" do
          json_post_v4 "/api/leads/lead_with_opportunity", invalid_params
          expect(response.status).to eq(404)
        end
      end

      context "invalid lead param" do
        let(:invalid_params) { params.merge(email: "invalid") }

        it "should return status 400" do
          json_post_v4 "/api/leads/lead_with_opportunity", invalid_params
          expect(response.status).to eq(400)
        end
      end

      context "invalid mandate param" do
        let(:invalid_params) { params.merge(phone_number: "invalid") }

        it "should return status 400" do
          json_post_v4 "/api/leads/lead_with_opportunity", invalid_params
          expect(response.status).to eq(400)
        end
      end
    end
  end

  describe "GET /api/leads/with_installation_id" do
    subject { json_get_v4 "/api/leads/with_installation_id", params }

    let(:lead) { create(:device_lead, mandate: create(:mandate)) }
    let(:params) {
      {
        installation_id: lead.installation_id
      }
    }

    context "with valid params" do
      it "returns a lead with installation_id" do
        subject
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["lead"]["id"]).to eq(lead.id)
      end
    end

    context "with invalid params" do
      it "returns a 400 for missing params" do
        json_get_v4 "/api/leads/with_installation_id"
        expect(response.status).to eq(400)
      end

      it "returns a 404 for non-existent installation_id" do
        json_get_v4 "/api/leads/with_installation_id", installation_id: "test"
        expect(response.status).to eq(404)
      end
    end
  end
end

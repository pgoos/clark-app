# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Leads::Generator do
  describe ".call" do
    context "email already exists" do
      let!(:lead) { create(:lead) }

      context "with valid params" do
        let(:lead_params) { {email: lead.email, terms: "new term", campaign: "new campaign"} }
        let(:mandate_params) { {first_name: "First", last_name: "Last"} }

        it "should update and return the lead" do
          result_lead = described_class.call(lead_params, mandate_params)
          mandate = result_lead.mandate
          expect(result_lead.id).to eq(lead.id)
          expect(result_lead.email).to eq(lead.email)
          expect(result_lead.terms).to eq(lead_params[:terms])
          expect(result_lead.campaign).to eq(lead_params[:campaign])
          expect(mandate.first_name).to eq(mandate_params[:first_name])
          expect(mandate.last_name).to eq(mandate_params[:last_name])
        end
      end

      context "with invalid params" do
        let(:lead_params) { {email: lead.email, terms: "new terms", campaign: nil} }
        let(:mandate_params) { {phone: "invalid"} }

        it "shoule return the lead with errors" do
          result_lead = described_class.call(lead_params)
          mandate = result_lead.mandate
          expect(result_lead.valid?).to eq(false)
          expect(mandate.valid?).to eq(false)
        end
      end
    end

    context "email doesn't exists" do
      context "with valid params" do
        let(:lead_params) do
          {
            email: "new@test.com",
            terms: "term",
            campaign: "campaign",
            registered_with_ip: Faker::Internet.ip_v4_address,
            source_data: {adjust: {utm_medium: "seo"}}
          }
        end
        let(:mandate_params) { {first_name: "First", last_name: "Last"} }

        it "should create a new lead" do
          expect { described_class.call(lead_params) }.to change(Lead, :count).by(1)
        end

        it "should create the lead with correct values" do
          lead = described_class.call(lead_params, mandate_params)
          mandate = lead.mandate
          expect(lead.email).to eq(lead_params[:email])
          expect(lead.terms).to eq(lead_params[:terms])
          expect(lead.campaign).to eq(lead_params[:campaign])
          expect(lead.registered_with_ip).to eq(lead_params[:registered_with_ip])
          expect(lead.source_data.with_indifferent_access).to match(lead_params[:source_data])
          expect(mandate.first_name).to eq(mandate_params[:first_name])
          expect(mandate.last_name).to eq(mandate_params[:last_name])
        end
      end

      context "with invalid params" do
        let(:lead_params) { {email: "abc", terms: nil, campaign: nil} }
        let(:mandate_params) { {phone: "invalid"} }

        it "shoule return the lead with errors" do
          lead = described_class.call(lead_params, mandate_params)
          mandate = lead.mandate
          expect(lead.valid?).to eq(false)
          expect(lead.persisted?).to eq(false)
          expect(mandate.valid?).to eq(false)
        end
      end
    end
  end
end

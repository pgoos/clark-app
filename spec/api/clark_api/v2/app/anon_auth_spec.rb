# frozen_string_literal: true

require "rails_helper"
require "support/api_schema_matcher"
require "ostruct"

include ApiSchemaMatcher

RSpec.describe ClarkAPI::V2::App::AnonAuth, :integration do
  describe "POST /api/app/anonauth" do
    it "creates a new lead and returns 201" do
      installation_id = "12321343343c32cc2c2c23324234c"
      json_post_v2 "/api/app/anonauth", {
        adjust: {"id" => 1, "text" => {"bla" => "blub"}}, installation_id: installation_id
      }

      expect(response.status).to eq(201)
      expect(json_response.errors).to be_blank
      expect(json_response.lead).to be_present
      expect(json_response.lead.adjust).to be_present
      expect(json_response.lead.mandate).to be_present
      expect(json_response.lead.mandate.state).to eq("not_started")
      expect(json_response.lead.installation_id).to eq(Lead.last.installation_id)
    end

    it "loads a lead and returns 202" do
      lead = create(:device_lead, mandate: create(:mandate))

      json_post_v2 "/api/app/anonauth", {
        adjust: {"id" => 1, "text" => {"bla" => "blub"}}, installation_id: lead.installation_id
      }

      expect(response.status).to eq(202)
      expect(json_response.errors).to be_blank
      expect(json_response.lead).to be_present
      expect(json_response.lead.mandate).to be_present
      expect(json_response.lead.installation_id).to eq(lead.installation_id)
    end

    it "creates a new lead and returns 201 if the existing lead was deactivated" do
      lead = create(:device_lead, mandate: create(:mandate),
                                              state:   "inactive")

      json_post_v2 "/api/app/anonauth", {
        adjust: {"id" => 1, "text" => {"bla" => "blub"}}, installation_id: lead.installation_id
      }

      expect(response.status).to eq(201)
      expect(json_response.errors).to be_blank
      expect(json_response.lead).to be_present
      expect(json_response.lead.adjust).to be_present
      expect(json_response.lead.mandate).to be_present
      expect(json_response.lead.mandate.state).to eq("not_started")
      expect(json_response.lead.installation_id).to eq(Lead.last.installation_id)
    end

    it "should append gps_adids" do
      lead = create(:device_lead, mandate: create(:mandate))

      expected_id = "XYZ987"
      json_post_v2 "/api/app/anonauth", {
        adjust:          {"id" => 1, "text" => {"bla" => "blub"}},
        installation_id: lead.installation_id,
        gps_adid:        expected_id
      }

      expect(Lead.last.has_advertiser_id?("id" => expected_id, "type" => "gps_adid")).to be_truthy
    end

    it "should append idfas" do
      lead = create(:device_lead, mandate: create(:mandate))

      expected_id = "XYZ987"
      json_post_v2 "/api/app/anonauth", {
        adjust:          {"id" => 1, "text" => {"bla" => "blub"}},
        installation_id: lead.installation_id,
        idfa:            expected_id
      }

      expect(Lead.last.has_advertiser_id?("id" => expected_id, "type" => "idfa")).to be_truthy
    end

    it "missing installation id returns a 400" do
      json_post_v2 "/api/app/anonauth", {adjust: {"id" => 1, "text" => {"bla" => "blub"}}}

      expect(response.status).to eq(400)
      expect(json_response.errors).to be_present
      expect(json_response.lead).to be_blank
    end
  end

  context "when method is not allowed" do
    it "should rescued with the correct status code" do
      json_get_v2 "/api/app/anonauth"

      expect(response.status).to eq(405)
    end

    it "should not send a Raven" do
      expect(Raven).not_to receive(:capture_exception)

      json_get_v2 "/api/app/anonauth"
    end

    it "should log the exception" do
      expect(Rails.logger).to receive(:error).with(an_instance_of(Grape::Exceptions::MethodNotAllowed))

      json_get_v2 "/api/app/anonauth"
    end
  end
end

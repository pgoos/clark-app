# frozen_string_literal: true

require "rails_helper"

# NOTE: slow test or categories API implementation -
#       Finished in 2 minutes 43.9 seconds (files took 12.88 seconds to load) MBP 2015 i7
RSpec.describe ClarkAPI::V2::Companies, :integration do
  context "GET /api/companies" do
    let!(:company) { create(:company, name: "Basler") }
    let!(:inactive_company) { create(:company, :inactive) }

    it "returns all companies which are active" do
      expected_response = [
        {
          "id" => company.id,
          "name" => "Basler",
          "name_without_hyphenation" => "Basler",
          "name_hyphenated" => "",
          "logo" => ActionController::Base.helpers.asset_path(company.logo),
          "ident" => company.ident,
          "details" => {},
          "average_response_time" => nil
        }
      ]
      json_get_v2 "/api/companies"

      expect(response.status).to eq(200)
      expect(json_response.companies.count).to eq(1)
      expect(json_response.companies).to eq(expected_response)
    end
  end

  context "POST /api/companies/missing" do
    it "sends email with company name to service" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      expect {
        json_post_v2 "/api/companies/missing", name: "abc"
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response.status).to eq(201)
    end

    it "missing company name does not send an email" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      expect {
        json_post_v2 "/api/companies/missing"
      }.to change { ActionMailer::Base.deliveries.count }.by(0)

      expect(response.status).to eq(400)
    end

    it "returns 401 if the user is not singed in" do
      json_post_v2 "/api/companies/missing", name: "abc"
      expect(response.status).to eq(401)
    end
  end
end

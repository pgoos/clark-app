# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Subcompanies, :integration do
  let(:user)       { create :user, mandate: mandate }
  let(:mandate)    { create :mandate, :created }
  let(:subcompany) { create(:subcompany) }

  describe "GET /by_category/:ident" do
    let!(:plan) { create(:plan, category: category, company: subcompany.company, subcompany: subcompany) }

    before do
      login_as user, scope: :user

      json_get_v4 "/api/retirement/subcompanies/by_category/#{category.ident}"
    end

    context "with retirement-related ident" do
      let(:category) { create(:category, ident: "f0a0e78c") }
      let(:expected_response) do
        {
          subcompanies: [
            {id: subcompany.id, name: subcompany.name}
          ]
        }.to_json
      end

      it { expect(response).to be_ok }
      it { expect(response.body).to eq expected_response }
    end

    context "with ident not related to retirement" do
      let(:category) { create(:category, :suhk) }
      let(:message) { "not valid, please specify a retirement-related ident" }

      it { expect(response).to be_bad_request }
      it { expect(json_response.errors.api.ident).to include(message) }
    end
  end
end

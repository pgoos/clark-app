# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Categories, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  describe "GET /api/retirement/categories/by_pillar" do
    let(:personal) { create :category, :private_rentenversicherung }
    let(:corporate) { create :category, :kapitallebensversicherung }
    let(:unsupported_for_calculations) { create :category, :riester_fonds_non_insurance }

    let!(:personal_pillar) do
      create :umbrella_category,
             ident: "vorsorgeprivat",
             included_category_ids: [personal.id]
    end

    let!(:corporate_pillar) do
      create :umbrella_category,
             ident: "1ded8a0f",
             included_category_ids: [corporate.id, unsupported_for_calculations.id]
    end

    before { login_as user, scope: :user }

    it "reponds with a list of pillars" do
      json_get_v4 "/api/retirement/categories/by_pillar"
      expect(response.status).to eq 200

      pillars = json_response["pillars"]

      expect(pillars).to be_kind_of Array
      expect(pillars.size).to eq 2
      expect(pillars.map { |p| p["id"] }).to \
        match_array [personal_pillar.id, corporate_pillar.id]

      expect(pillars.first["included_categories"]).to be_kind_of Array
      expect(pillars.first["included_categories"].size).to eq 1

      expect(pillars.second["included_categories"]).to be_kind_of Array
      expect(pillars.second["included_categories"].size).to eq 1
    end
  end
end

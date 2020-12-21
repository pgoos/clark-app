# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::Questionnaires, :integration do
  let(:admin) { create(:admin, role: create(:role)) }

  before do
    login_as(admin, scope: :admin)
  end

  describe "GET /api/admin/questionnaires/active" do
    it "returns all iquiry categories which are visible to customer" do
      questionnaire = create :questionnaire
      create :questionnaire
      create :category, questionnaire: questionnaire

      json_admin_get_v1 "/api/admin/questionnaires/active"

      expect(response.status).to eq(200)
      expect(json_response["questionnaires"]).to be_present
      expect(json_response["questionnaires"].size).to eq 1
      expect(json_response["questionnaires"][0]["name"]).to eq questionnaire.name
    end
  end
end

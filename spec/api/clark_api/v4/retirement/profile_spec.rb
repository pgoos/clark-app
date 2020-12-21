# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Profile, :integration do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate, :created, birthdate: Date.new(1985, 1, 1) }

  describe "GET /api/retirement/profile" do
    it "exposes a retirement information of current mandate" do
      login_as user, scope: :user
      json_get_v4 "/api/retirement/profile"

      expect(response.status).to eq 200
      expect(json_response["legal_retirement_age"]).to eq 67
      expect(Date.parse(json_response["retirement_date"]))
        .to eq Date.parse((mandate.birthdate + 67.years).to_s)
    end

    context "when non-authorized" do
      it "responds with an error" do
        json_get_v4 "/api/retirement/profile"
        expect(response.status).to eq 401
      end
    end
  end
end

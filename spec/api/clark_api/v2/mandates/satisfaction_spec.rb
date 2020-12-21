# frozen_string_literal: true
require "rails_helper"

# TODO: it 'requires authentication' needs refactoring, and to be included here
RSpec.describe ClarkAPI::V2::Mandates::Satisfaction, :integration do
  context "POST /api/mandates/:id/satisfaction/nps" do
    let(:user) { create(:user, confirmed_at: Time.zone.now) }
    let(:mandate) do
      create(:mandate,
                         confirmed_at: 100.days.ago,
                         state:      "accepted",
                         user:       user)
    end

    it "requires authentication" do
      logout
      json_post_v2 "/api/mandates/#{mandate.id}/satisfaction/nps", value: 10
      expect(response.status).to eq(401)
    end

    it "creates an nps score for user" do
      user = create(:user, mandate: mandate)
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{user.mandate.id}/satisfaction/nps", value: 5

      expect(response.status).to eq(410)
    end

    it "creates an nps refusal for the user if the score is nil" do
      user = create(:user, mandate: mandate)
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{user.mandate.id}/satisfaction/nps", value: nil

      expect(response.status).to eq(410)
    end
  end


  context "POST /api/mandates/:id/satisfaction/nps/comment" do
    let(:user) { create(:user, confirmed_at: Time.zone.now) }
    let(:mandate) do
      create(:mandate,
                         confirmed_at: 100.days.ago,
                         state:      "accepted",
                         user:       user)
    end

    it "requires authentication" do
      logout
      json_post_v2 "/api/mandates/#{mandate.id}/satisfaction/nps/comment", comment: "Sugoi!"
      expect(response.status).to eq(401)
    end

    it "creates a comment for nps score" do
      user = create(:user, mandate: mandate)
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{user.mandate.id}/satisfaction/nps/comment", comment: "Sugoi!"

      expect(response.status).to eq(410)
    end
  end
end

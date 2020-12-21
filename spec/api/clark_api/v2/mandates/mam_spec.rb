# frozen_string_literal: true
require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates::Mam, :integration do
  context "PATCH /api/mandates/:id/mam" do
    let(:mandate) { create(:mandate, :mam) }
    let(:valid_card) { "992223020632830" }
    let(:invalid_card) { Domain::Partners::Mocks::FakeMilesMoreClient.invalid_mam_account_number }

    it "gets an invalid card and rejects it" do
      login_as(mandate.user, scope: :user)
      json_put_v2("/api/mandates/#{mandate.id}/mam", {
        id: mandate.id,
        loyalty: {
          mam: {
            mmAccountNumber: invalid_card
          }
        }
      })

      expect(response.status).to eq(400)
      expect(json_response.errors[0])
        .to eq("Code: 35 Message: Validation Error: Card number is invalid: #{invalid_card}")
      expect(mandate.loyalty["mam"]).to eq({})
    end

    it "gets a valid card and saves it" do
      login_as(mandate.user, scope: :user)
      json_put_v2("/api/mandates/#{mandate.id}/mam", {
        id: mandate.id,
        loyalty: {
          mam: {
            mmAccountNumber: valid_card
          }
        }
      })

      expect(response.status).to eq(200)
      expect(mandate.loyalty["mam"]["mmAccountNumber"]).to eq(valid_card)
    end
  end
end

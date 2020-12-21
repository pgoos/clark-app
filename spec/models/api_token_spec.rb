# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiToken, type: :model do
  let(:api_token) do
    build(
      :api_token,
      token: token,
      description: "TestTokenDescription"
    )
  end

  context "with correct arguments" do
    let(:token) { "TestToken" }

    it "is valid" do
      expect(api_token).to be_valid
    end
  end

  context "with missing token" do
    let(:token) { nil }

    it "is invalid" do
      expect(api_token).to be_invalid
      expect(api_token.errors.size).to eq(1)
      expect(api_token.errors[:token]).to include(I18n.t("errors.messages.blank"))
    end
  end

  context "with existing token" do
    let(:token) { "TestToken" }

    it "is invalid" do
      create(:api_token, token: token)

      expect(api_token).to be_invalid
      expect(api_token.errors.size).to eq(1)
      expect(api_token.errors[:token]).to include(I18n.t("errors.messages.taken"))
    end
  end
end

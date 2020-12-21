# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manager::BaseHelper, type: :helper do
  describe "#enabled_header?" do
    before do
      allow(Settings).to receive_message_chain(:manager, :enabled_headers, :referral).and_return false
      allow(Settings).to receive_message_chain(:manager, :enabled_headers, :profile).and_return true
      allow(Settings).to receive_message_chain(:manager, :enabled_headers, :testing)
    end

    context "when section exists in settings" do
      it "returns true if setting is set to true" do
        expect(helper.enabled_header?("profile")).to eq true
      end

      it "returns false if setting is set to false" do
        expect(helper.enabled_header?("referral")).to eq false
      end
    end

    context "when section does not exist in settings" do
      it "returns nil when setting is not found in settings" do
        expect(helper.enabled_header?("testing")).to eq nil
      end
    end
  end

  describe "#phone_number" do
    before do
      allow(Settings).to receive_message_chain(:clark_agent, :phone).and_return "+43 1 3860870"
    end

    it "returns properly formatted phone number from settings" do
      expect(helper.agent_phone_number).to eq "01 3860870"
    end
  end
end

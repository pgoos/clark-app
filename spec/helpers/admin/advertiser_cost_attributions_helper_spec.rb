# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdvertiserCostAttributionsHelper do
  subject do
    object = Object.new
    object.extend Admin::AdvertiserCostAttributionsHelper
    object
  end

  describe "#options_for" do
    before do
      create(
        :advertiser_channel_mapping,
        :facebook,
        ad_provider:   "CuteAds",
        campaign_name: "Campaign 1",
        adgroup_name:  "Ad Group",
        creative_name: "CREATIVE NAME"
      )

      create(
        :advertiser_channel_mapping,
        :facebook,
        ad_provider:   "CuteAds",
        campaign_name: "Campaign 2",
        adgroup_name:  nil,
        creative_name: "CREATIVE NAME"
      )
    end

    it "returns options for ad_provider" do
      expect(subject.options_for(:ad_provider)).to match_array ["CuteAds"]
    end

    it "returns options for campaign_name" do
      expect(subject.options_for(:campaign_name)).to match_array ["Campaign 1", "Campaign 2"]
    end

    it "returns options for adgroup_name" do
      expect(subject.options_for(:adgroup_name)).to match_array ["Ad Group"]
    end

    it "returns options for creative_name" do
      expect(subject.options_for(:creative_name)).to match_array ["CREATIVE NAME"]
    end

    it "does not send a notification to Sentry" do
      expect(Raven).not_to receive(:capture_message)
      subject.options_for(:foo)
    end

    context "when option values exceed the limit" do
      before { stub_const("#{described_class}::OPTIONS_WARN_LIMIT", 2) }

      it "sends a notification to Sentry" do
        expect(Raven).to receive(:capture_message)
        subject.options_for(:foo)
      end
    end
  end
end

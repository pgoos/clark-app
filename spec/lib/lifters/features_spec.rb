# frozen_string_literal: true

require "rails_helper"

RSpec.describe Features do
  context "#active?" do
    let!(:active_feature) {create(:feature_switch, key: "active", active: true)}
    let!(:inactive_feature) {create(:feature_switch, key: "inactive", active: false)}

    it "is true for active feature" do
      expect(described_class.active?("active")).to eq(true)
    end

    it "is false for inactive feature" do
      expect(described_class.active?("inactive")).to eq(false)
    end

    it "is false for nil" do
      expect(described_class.active?(nil)).to eq(false)
    end

    it "is false for the empty string of with white space" do
      expect(described_class.active?("\n\t\r")).to eq(false)
    end
  end

  context "toggle features" do
    let!(:active_feature) { create(:feature_switch, key: "active", active: true) }
    let!(:inactive_feature) { create(:feature_switch, key: "inactive", active: false) }
    let(:authorized_admin) { create(:admin, access_flags: [:switch_features]) }
    let(:unauthorized_admin) { create(:admin, access_flags: []) }

    it "allows to activate a feature" do
      described_class.toggle_feature!("inactive", authorized_admin)
      expect(described_class.active?("inactive")).to be_truthy
    end

    it "does not activate a feature without permission" do
      described_class.toggle_feature!("inactive", unauthorized_admin)
      expect(described_class.active?("inactive")).to be_falsey
    end

    it "allows to turn off a feature" do
      described_class.toggle_feature!("active", authorized_admin)
      expect(described_class.active?("active")).to be_falsey
    end

    it "does not turn off a feature without permission" do
      described_class.toggle_feature!("active", unauthorized_admin)
      expect(described_class.active?("active")).to be_truthy
    end
  end

  context "#reached_limit?" do
    let!(:unlimited_feature) { create(:feature_switch, key: "unlimited", active: true) }
    let!(:limited_feature) do
      create(:feature_switch, key: "limited", active: true, limit: 10)
    end
    let!(:inactive_feature) do
      create(:feature_switch, key: "inactive", active: false)
    end

    it "is true if feature inactive" do
      expect(described_class.reached_limit?("inactive", 0)).to eq(true)
    end

    it "is true if value is above limit" do
      expect(described_class.reached_limit?("limited", 20)).to eq(true)
    end

    it "is false if value bellow limit and feature active" do
      expect(described_class.reached_limit?("limited", 5)).to eq(false)
    end

    it "is false if feature is unlimited" do
      expect(described_class.reached_limit?("unlimited", 5)).to eq(false)
    end
  end

  context "constants" do
    it { expect(described_class).to have_constant(:SBOT) }
    it { expect(described_class).to have_constant(:OPSUI_MANDATE_CREATION) }
    it { expect(described_class).to have_constant(:FEATURE_AUTO_CANCEL_INQUIRIES_AFTER_TIMEOUT) }
    it { expect(described_class).to have_constant(:FEATURE_RETIREMENT_2018_V1) }
    it { expect(described_class).to have_constant(:OFFER_AUTOMATION_BY_RULE_MATRIX) }
    it { expect(described_class).to have_constant(:OCR) }
    it { expect(described_class).to have_constant(:OCR_MASTER_DATA_UPLOAD) }
    it { expect(described_class).to have_constant(:RATING_MODAL) }
    it { expect(described_class).to have_constant(:FIXED_OPPORTUNITY_SOURCE_DESCRIPTION) }
    it { expect(described_class).to have_constant(:MANDATE_REMINDER1) }
    it { expect(described_class).to have_constant(:MANDATE_REMINDER2) }
    it { expect(described_class).to have_constant(:MANDATE_REMINDER3) }
    it { expect(described_class).to have_constant(:ORDER_AUTOMATION) }
    it { expect(described_class).to have_constant(:RETIREMENT_COCKPIT_ENABLED) }
    it { expect(described_class).to have_constant(:ARISECUR) }
    it { expect(described_class).to have_constant(:DISABLE_DISALLOWED_API_PARTNER_MANDATE_CREATION) }
    it { expect(described_class).to have_constant(:RECOMMENDATION_OVERVIEW_SEGMENT) }
    it { expect(described_class).to have_constant(:RECOMMENDATION_OVERVIEW_2020) }
    it { expect(described_class).to have_constant(:RECOMMENDATION_OVERVIEW_LIST) }
  end
end

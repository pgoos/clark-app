# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_reoccurring_advice_feature_switch"

describe AddReoccurringAdviceFeatureSwitch do
  let(:feature_key) { Features::REOCCURRING_ADVICE }

  describe "#data" do
    it "creates a new feature" do
      described_class.new.data
      expect(FeatureSwitch.find_by(key: feature_key)).to be_instance_of FeatureSwitch
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      described_class.new.data
      described_class.new.rollback

      expect(FeatureSwitch.find_by(key: feature_key)).to be_nil
    end
  end
end

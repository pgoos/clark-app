# frozen_string_literal: true

require "rails_helper"
require "composites/experiments"

RSpec.describe Experiments::Constituents::TestGroupSelection::Repositories::FeatureSwitchersRepository, :integration do
  let(:test_feature_name) { "TEST_FEATURE" }

  describe "#active?" do
    context "feature is active" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(test_feature_name)
          .and_return(true)
      end

      it "returns false result" do
        expect(subject.send(:active?, test_feature_name)).to be_truthy
      end
    end

    context "feature is inactive" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(test_feature_name)
          .and_return(false)
      end

      it "returns false result" do
        expect(subject.send(:active?, test_feature_name)).to be_falsy
      end
    end
  end

  describe "#inactive?" do
    context "feature is active" do
      before do
        allow(Features)
          .to receive(:inactive?)
          .with(test_feature_name)
          .and_return(false)
      end

      it "returns false result" do
        expect(subject.send(:inactive?, test_feature_name)).to be_falsy
      end
    end

    context "feature is inactive" do
      before do
        allow(Features)
          .to receive(:inactive?)
          .with(test_feature_name)
          .and_return(true)
      end

      it "returns false result" do
        expect(subject.send(:inactive?, test_feature_name)).to be_truthy
      end
    end
  end
end

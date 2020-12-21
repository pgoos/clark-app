# frozen_string_literal: true

require "rails_helper"
require "composites/experiments"

RSpec.describe Experiments::Constituents::TestGroupSelection::Interactors::DefineTestGroup do
  let(:test_feature) { "TEST_FEATURE_NAME" }

  describe "#call" do
    context "test group" do
      let(:test_percentage_value) { 100 }

      context "when TEST_FEATURE Feature is ON" do
        before do
          allow(Features)
            .to receive(:active?)
            .with(test_feature)
            .and_return(true)
        end

        it "returns true (test group)" do
          expect(subject.call(test_percentage_value, test_feature).test_group).to be_truthy
        end
      end

      context "when TEST_FEATURE Feature is OFF" do
        before do
          allow(Features)
            .to receive(:active?)
            .with(test_feature)
            .and_return(false)
        end

        it "returns false (control group)" do
          expect(subject.call(test_percentage_value, test_feature).test_group).to be_falsey
        end
      end
    end

    context "control group" do
      let(:test_percentage_value) { 0 }

      context "when TEST_FEATURE Feature is ON" do
        before do
          allow(Features)
            .to receive(:active?)
            .with(test_feature)
            .and_return(true)
        end

        it "returns true (test group)" do
          expect(subject.call(test_percentage_value, test_feature).test_group).to be_falsey
        end
      end

      context "when TEST_FEATURE Feature is OFF" do
        before do
          allow(Features)
            .to receive(:active?)
            .with(test_feature)
            .and_return(false)
        end

        it "returns false (control group)" do
          expect(subject.call(test_percentage_value, test_feature).test_group).to be_falsey
        end
      end
    end
  end
end

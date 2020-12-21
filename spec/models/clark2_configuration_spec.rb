# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clark2Configuration, :integration, type: :model do
  describe "#validate_probability" do
    it "accepts a value between 0 and 100" do
      model = described_class.new(key: "ios_probability", value: "20")

      expect(model.valid?).to eq(true)
    end

    it "does not accept a value out of range" do
      model = described_class.new(key: "ios_probability", value: "120")

      expect(model.valid?).to eq(false)
    end
  end

  shared_examples "a probability" do
    it "returns probability record" do
      create :clark2_configuration, key: :foo, value: {}
      expect(described_class.send(method)).to eq nil

      probability = create :clark2_configuration, method
      expect(described_class.send(method)).to eq probability
    end

    it "returns probability value" do
      create :clark2_configuration, method, value: 90
      expect(described_class.send(:"#{method}_value")).to eq 90
    end
  end

  describe ".ios_probability" do
    let(:method) { :ios_probability }

    it_behaves_like "a probability"
  end

  describe ".android_probability" do
    let(:method) { :android_probability }

    it_behaves_like "a probability"
  end

  describe ".other_probability" do
    let(:method) { :other_probability }

    it_behaves_like "a probability"
  end
end

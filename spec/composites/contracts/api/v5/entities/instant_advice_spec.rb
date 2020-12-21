# frozen_string_literal: true

require "rails_helper"
require "grape-entity"

RSpec.describe Contracts::Api::V5::Entities::InstantAdvice, integration: true do
  let(:instant_advice) do
    OpenStruct.new(
      category_description: "category_description",
      assessment_explanation: "assessment_explanation",
      total_evaluation: { value: "80", description: "Some" },
      customer_review: { value: "79", description: "Some" },
      coverage_degree: { value: "80", description: "Some" },
      popularity: { value: "10", description: "Some" },
      price_level: { value: "90", description: "Some" },
      claim_settlement: { value: "22", description: "Some" }
    )
  end

  let(:entity) do
    described_class.new(instant_advice).as_json
  end

  let(:attributes) { entity[:attributes] }

  it "has category_description attribute" do
    expect(attributes).to include(category_description: "category_description")
  end

  it "has assessment_explanation attribute" do
    expect(attributes).to include(assessment_explanation: "assessment_explanation")
  end

  describe "#total_evaluation" do
    let(:total_evaluation) { attributes[:total_evaluation] }

    it "has value attribute" do
      expect(total_evaluation).to include(value: "80")
    end

    it "has description attribute" do
      expect(total_evaluation).to include(description: "Some")
    end
  end

  describe "#customer_review" do
    let(:customer_review) { attributes[:customer_review] }

    it "has value attribute" do
      expect(customer_review).to include(value: "79")
    end

    it "has description attribute" do
      expect(customer_review).to include(description: "Some")
    end
  end

  describe "#coverage_degree" do
    let(:coverage_degree) { attributes[:coverage_degree] }

    it "has value attribute" do
      expect(coverage_degree).to include(value: "80")
    end

    it "has description attribute" do
      expect(coverage_degree).to include(description: "Some")
    end
  end

  describe "#popularity" do
    let(:popularity) { attributes[:popularity] }

    it "has value attribute" do
      expect(popularity).to include(value: "10")
    end

    it "has description attribute" do
      expect(popularity).to include(description: "Some")
    end
  end

  describe "#price_level" do
    let(:price_level) { attributes[:price_level] }

    it "has value attribute" do
      expect(price_level).to include(value: "90")
    end

    it "has description attribute" do
      expect(price_level).to include(description: "Some")
    end
  end

  describe "#claim_settlement" do
    let(:claim_settlement) { attributes[:claim_settlement] }

    it "has value attribute" do
      expect(claim_settlement).to include(value: "22")
    end

    it "has description attribute" do
      expect(claim_settlement).to include(description: "Some")
    end
  end
end

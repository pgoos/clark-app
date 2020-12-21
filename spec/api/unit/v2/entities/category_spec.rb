# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Entities::Category, integration: true do
  let(:questionnaire) { nil }
  let(:category) { create(:category, life_aspect: "things", questionnaire: questionnaire) }
  let(:entity) { described_class.new(category).as_json }

  context "coverage_features" do
    it "return correct attributes" do
      coverages = entity[:coverage_features]

      expect(coverages).to be_kind_of(Array)
      expect(coverages).to all be_kind_of(Hash)
      expect(coverages).to all include(section: "Any section")
      expect(coverages).to all include(description: "Description")
    end
  end

  describe "offer_type field" do
    it "is included in the JSON response" do
      expect(entity).to include(:offer_type)
    end

    context "when category is related to health" do
      it "is exposed as `life_and_health_offer`" do
        allow(category).to receive(:life_aspect).and_return("health")

        expect(entity).to include(offer_type: "life_and_health_offer")
      end
    end

    context "when questionnaire has an active offer automation" do
      let(:questionnaire) { create(:offer_automation, :active).questionnaire }

      it "is exposed as `instant_offer`" do
        expect(entity).to include(offer_type: "instant_offer")
      end
    end

    context "when questionnaire doesn't have an active offer automation" do
      let(:questionnaire) { create(:offer_automation).questionnaire }

      it "is exposed as `non_instant_offer`" do
        expect(entity).to include(offer_type: "non_instant_offer")
      end
    end
  end
end

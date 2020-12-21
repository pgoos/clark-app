# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Intents::RoboAdvisorAdvices do
  let(:logger)      { Logger.new("/dev/null") }
  let(:product)     { create(:product) }
  let(:last_advice) { Interaction::Advice.last }

  let(:admin) { create(:advice_admin) }

  let(:attributes) do
    {
      content:    "base advice text",
      identifier: "some advice",
      rule_id:    "131"
    }
  end

  let(:replaceable_attributes) do
    attributes.merge(
      identifier:     "private_liability_with_household",
      rule_id:        "25.5",
      source_rule_id: "10.0",
      classification: :keeper # this advice is a switcher, but we pass both modes
    )
  end

  before do
    Domain::Classification::QualityForCustomerClassifier.load_classification
    allow(Batch).to receive(:handle_errors) { |**_, &block| block.call }
  end

  # segments advice uses the new robo advisor strategy for content building
  context "promoting to segments advice" do
    context "advice has segments" do
      it "changes content" do
        subject.execute(product, replaceable_attributes, logger, [admin])
        expect(last_advice.content).not_to eq(replaceable_attributes[:content])
      end
    end

    context "advice has no segments" do
      it "keeps content" do
        subject.execute(product, attributes, logger, [admin])
        expect(last_advice.content).to eq(attributes[:content])
      end
    end
  end

  context "when there is previous contact" do
    before do
      subject.execute(product, attributes, logger, [admin])
    end

    it "returns zero" do
      expect(subject.execute(product, attributes, logger, [admin])).to eq 0
    end
  end

  context "classification" do
    before do
      subject.execute(product, replaceable_attributes, logger, [admin])
    end

    it "add source rule id as classification" do
      expect(last_advice.classifications).to include("10.0")
    end

    it "add keeper switcher classification when output is of a switcher" do
      expect(last_advice.classifications).to include("switcher")
    end

    it "add keeper switcher classification when present as classification" do
      expect(last_advice.classifications).to include("keeper")
    end
  end
end

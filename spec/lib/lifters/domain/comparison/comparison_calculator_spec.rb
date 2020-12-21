# frozen_string_literal: true

require "rails_helper"
require "lifters/features"

RSpec.describe Domain::Comparison::ComparisonCalculator do
  let(:mandate) { create(:mandate) }
  let(:questionnaire_response) { create(:questionnaire_response, mandate: mandate) }
  let!(:candidate_context) do
    candidate_context = n_double("candidate_context")
    allow(candidate_context).to receive(:request=).with(anything) do |xml|
      @generated_xml = xml
      xml
    end
    allow(candidate_context).to receive_message_chain(:adapter, :response).and_return(questionnaire_response)
    allow(candidate_context).to receive(:request).and_return(@generated_xml)
    allow(candidate_context).to receive(:response=).with(anything)
    candidate_context
  end

  before(:each) do
    allow_any_instance_of(Savon::Client).to receive(:call).and_return('')
    allow(Features).to receive(:active?).with(String).and_return(true)
  end

  it "maps to the right comparison class if found" do
    expect(Softfair::HouseholdContents::ComparisonCalculator).to receive(:new).and_call_original
    described_class.generate_comparison(Features::AUTOMATED_HOUSEHOLD_OFFER_FROM_COMPARISON, candidate_context)
  end

  it "calls generate comparison on the delegate class if found" do
    expect_any_instance_of(Softfair::HouseholdContents::ComparisonCalculator).to receive(:generate_comparison).and_call_original
    described_class.generate_comparison(Features::AUTOMATED_HOUSEHOLD_OFFER_FROM_COMPARISON, candidate_context)
  end

  it "raises a standard error, if no comparison availble" do
    expect {
      described_class.generate_comparison("FEATURE_DOES_NOT_EXIST", candidate_context)
    }.to raise_error(StandardError, "No provider found!")
  end

  it "raises an error, if the feature is switched off" do
    sample_key = described_class::COMPARISON_PROVIDERS.keys.sample

    allow(Features).to receive(:active?).with(sample_key).and_return(false)

    expect {
      described_class.generate_comparison(sample_key, candidate_context)
    }.to raise_error("Feature '#{sample_key}' is not active!")
  end
end

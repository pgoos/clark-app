# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateDisabilityComparisonJob, type: :job do
  let(:positive_integer) { 1 + (rand * 100).round }
  let(:opportunity_id) { positive_integer }
  let(:opportunity) { instance_double(Opportunity) }
  let(:override_params) { {age: positive_integer + 1, pension: positive_integer + 2} }
  let(:params) { {opportunity_id: opportunity_id, override_params: override_params} }
  let(:candidate_context) do
    instance_double(Domain::OfferGeneration::Disability::DisabilityCandidateContext)
  end

  before do
    allow(Opportunity).to receive(:find).with(opportunity_id).and_return(opportunity)
    allow(Domain::OfferGeneration::Disability::DisabilityCandidateContext)
      .to receive(:from_opportunity).and_return(candidate_context)
  end

  it "should generate the comparison" do
    expect(Domain::Comparison::ComparisonCalculator).to receive(:generate_comparison)
      .with(Features::DISABILITY_INSURANCE_COMPARISON, candidate_context)
    subject.perform(params)
  end

  it "should use the override params with indifferent access" do
    subject.send(:read_args, params)
    expect(subject.instance_variable_get("@override_params")["age"]).to eq(positive_integer + 1)
  end

  context "opportunity association" do
    let(:metadata) { {"key1" => {"key2" => "value"}} }

    before do
      # Usually the arguments would be set by calling perform or perform_later. We're simulating
      # by setting them here:
      subject.arguments << params
      allow(opportunity).to receive(:metadata).and_return(metadata)
    end

    it "should add the job id the opportunity's metadata" do
      expected_metadata         = metadata.dup
      expected_metadata["jobs"] = [subject.job_id]

      expect(opportunity).to receive(:update_attributes!).with(metadata: expected_metadata)
      subject.enqueue
    end

    it "should add the job id only once to the opportunity's metadata" do
      metadata["jobs"] = [subject.job_id]

      expect(opportunity).not_to receive(:update_attributes!)
      subject.enqueue
    end

    it "should not destroy existing job ids at the opportunity metadata" do
      existing_id               = "existing_id_value"
      metadata["jobs"]          = [existing_id]

      expected_metadata         = metadata.dup
      expected_metadata["jobs"] = [existing_id, subject.job_id]

      expect(opportunity).to receive(:update_attributes!).with(metadata: expected_metadata)
      subject.enqueue
    end
  end
end

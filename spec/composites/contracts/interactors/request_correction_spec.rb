# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/interactors/request_correction"

RSpec.describe Contracts::Interactors::RequestCorrection do
  let(:admin_id) { 1 }
  let(:customer) { double("customer", id: 1) }
  let(:contract_repo) { double("contract_repo", update_analysis_state!: true) }
  let(:interaction_repo) { double("interaction_repo", register_sent_email!: true) }
  let(:customer_notifier_double) { class_double("Contracts::Outbound::CustomerNotifier", request_correction: true) }
  let(:params) do
    {
      "id" => customer.id,
      "admin_id" => admin_id,
      "possible_reasons" => [:insurance_number],
      "additional_information" => "please reupload document",
    }
  end
  let(:contract) do
    double(
      id: 1,
      customer_id: 1,
      analysis_state: Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS
    )
  end

  before do
    allow(subject).to receive(:contract_repo).and_return(contract_repo)
    allow(subject).to receive(:interaction_repo).and_return(interaction_repo)
    allow(subject).to receive(:find_contract).with(contract.id).and_return(contract)
    allow(subject).to receive(:customer_notifier).and_return(customer_notifier_double)
  end

  it "updates contract analysis state" do
    expect(contract_repo).to receive(:update_analysis_state!).with(contract, analysis_state: "analysis_failed")

    subject.call(params)
  end

  it "creates email interaction" do
    expected_params = {
      admin_id: admin_id,
      contract_id: contract.id,
      customer_id: contract.customer_id,
      content: "Rückfrage zu deinem Vertrag",
      metadata: { title: "no product can be created" },
    }

    expect(interaction_repo).to receive(:register_sent_email!).with(expected_params)

    subject.call(params)
  end

  it "sends notification" do
    possible_reasons, additional_information = params.values_at("possible_reasons", "additional_information")

    expect(customer_notifier_double)
      .to receive(:request_correction).with(contract, possible_reasons, additional_information)

    subject.call(params)
  end
end

# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/state_machines/contract_analysis_state_machine"

describe Contracts::StateMachines::ContractAnalysisStateMachine do
  subject { described_class.new(details_missing) }

  let(:details_missing) { Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING }
  let(:under_analysis) { Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS }
  let(:analysis_failed) { Contracts::Entities::Contract::AnalysisState::ANALYSIS_FAILED }
  let(:details_complete) { Contracts::Entities::Contract::AnalysisState::DETAILS_COMPLETE }
  let(:customer_canceled_analysis) { Contracts::Entities::Contract::AnalysisState::CUSTOMER_CANCELED_ANALYSIS }

  it { expect(subject).to have_states(*Contracts::Entities::Contract::AnalysisStates.values) }

  it "throws an error if transition can't be done" do
    expect { described_class.fire_event!(details_complete, :request_analysis) }
      .to raise_error described_class::InvalidTransition
  end

  context "when details missing" do
    it do
      expect(subject)
        .to handle_events(
          :request_analysis,
          :customer_provides_details,
          :customer_cancels_analysis,
          when: details_missing
        )
    end

    it { expect(subject).to reject_events :finish_analysis, :information_missing, when: details_missing }
  end

  context "when under analysis" do
    it do
      expect(subject)
        .to handle_events(
          :finish_analysis,
          :information_missing,
          :customer_provides_details,
          :customer_cancels_analysis,
          when: under_analysis
        )
    end

    it { expect(subject).to reject_events :request_analysis, when: under_analysis }
  end

  context "when analysis failed" do
    it do
      expect(subject)
        .to handle_events(
          :request_analysis,
          :customer_provides_details,
          :customer_cancels_analysis,
          when: analysis_failed
        )
    end

    it { expect(subject).to reject_events :finish_analysis, :information_missing, when: analysis_failed }
  end

  context "when details complete" do
    it do
      expect(subject)
        .to handle_events(
          :customer_cancels_analysis,
          when: details_complete
        )
    end

    it do
      expect(subject)
        .to reject_events(
          :request_analysis,
          :finish_analysis,
          :information_missing,
          :customer_provides_details,
          when: details_complete
        )
    end
  end

  context "when customer canceled analysis" do
    it do
      expect(subject)
        .to reject_events(
          :request_analysis,
          :finish_analysis,
          :information_missing,
          :customer_provides_details,
          when: customer_canceled_analysis
        )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::At::InformationProvidedPolicy do
  subject { described_class.new(situation) }

  let(:situation) { double :situation }

  before do
    allow(situation).to receive(:current_statement_on_hand?).and_return(
      current_statement_on_hand
    )
  end

  context "when current_statement_on_hand is answered" do
    let(:current_statement_on_hand) { true }

    it { expect(subject.eligible?).to eq true }
  end

  context "when current_statement_on_hand isn't answered" do
    let(:current_statement_on_hand) { false }

    it { expect(subject.eligible?).to eq false }
  end
end

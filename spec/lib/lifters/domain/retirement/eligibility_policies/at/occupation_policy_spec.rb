# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::At::OccupationPolicy do
  subject { described_class.new(situation) }

  let(:situation) { double :situation }

  context "when occupation is supported" do
    before { allow(situation).to receive(:occupation).and_return "Abteilungsleiter" }

    it { expect(subject.eligible?).to eq true }
  end

  context "when occupation is not supported" do
    context "when out of scope" do
      before { allow(situation).to receive(:occupation).and_return "Pensionisten" }

      it { expect(subject.eligible?).to eq false }
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::De::OccupationPolicy do
  subject { described_class.new(situation) }

  let(:situation) { double :situation }

  context "when occupation is supported" do
    before { allow(situation).to receive(:occupation).and_return "Abteilungsleiter" }

    it { expect(subject.eligible?).to eq true }
  end

  context "when occupation is not supported" do
    context "when out of scope" do
      before { allow(situation).to receive(:occupation).and_return "Schuler" }

      it { expect(subject.eligible?).to eq false }
    end

    context "when freelancer" do
      let(:occupation_description) do
        "und kein Mitglied einer berufsstandischen Kammer"
      end
      let(:occupation_details) do
        "und nicht gesetzlich rentenversichert"
      end

      before do
        allow(situation).to receive(:occupation).and_return "Freiberufler"
        allow(situation).to receive(:occupation_description).and_return occupation_description
        allow(situation).to receive(:occupation_details).and_return occupation_details
      end

      it { expect(subject.eligible?).to eq false }
    end
  end
end

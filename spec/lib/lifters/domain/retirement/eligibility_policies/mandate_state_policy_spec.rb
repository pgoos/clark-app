# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::MandateStatePolicy do
  subject { described_class.new(mandate) }

  let(:state) { nil }
  let(:customer_state) { nil }
  let(:mandate) { double(:mandate, state: state, customer_state: customer_state) }

  describe "#eligible?" do
    context "with common customer" do
      context "freebie" do
        let(:state) { "freebie" }

        it { expect(subject).not_to be_eligible }
      end

      context "not_started" do
        let(:state) { "not_started" }

        it { expect(subject).not_to be_eligible }
      end

      context "in_creation" do
        let(:state) { "in_creation" }

        it { expect(subject).not_to be_eligible }
      end

      context "created" do
        let(:state) { "created" }

        it { expect(subject).to be_eligible }
      end

      context "accepted" do
        let(:state) { "accepted" }

        it { expect(subject).to be_eligible }
      end
    end

    context "with clark2 customer" do
      let(:customer_state) { "prospect" }

      context "freebie" do
        let(:state) { "freebie" }

        it { expect(subject).not_to be_eligible }
      end

      context "not_started" do
        let(:state) { "not_started" }

        it { expect(subject).to be_eligible }
      end

      context "in_creation" do
        let(:state) { "in_creation" }

        it { expect(subject).to be_eligible }
      end

      context "created" do
        let(:state) { "created" }

        it { expect(subject).to be_eligible }
      end

      context "accepted" do
        let(:state) { "accepted" }

        it { expect(subject).to be_eligible }
      end
    end
  end

  describe "#out_of_scope?" do
    context "not eligible" do
      let(:state) { "freebie" }

      it { expect(subject).to be_out_of_scope }
    end

    context "eligible" do
      let(:state) { "created" }

      it { expect(subject).not_to be_out_of_scope }
    end
  end
end

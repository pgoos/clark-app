# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::AgePolicy do
  subject { described_class.new(birthdate) }

  describe "#eligible?" do
    context "without birth date" do
      let(:birthdate) { nil }

      it { expect(subject).not_to be_eligible }
    end

    context "in AT" do
      before { allow(Settings).to receive_message_chain("retirement.age").and_return 65 }

      context "with retirement year earlier than current year" do
        let(:birthdate) { Date.today - 66.years }

        it { expect(subject).not_to be_eligible }
      end

      context "with retirement year later than current year" do
        let(:birthdate) { Date.today - 64.years }

        it { expect(subject).to be_eligible }
      end
    end

    context "in DE" do
      before { allow(Settings).to receive_message_chain("retirement.age").and_return 67 }

      context "with retirement year earlier than current year" do
        let(:birthdate) { Date.today - 68.years }

        it { expect(subject).not_to be_eligible }
      end

      context "with retirement year later than current year" do
        let(:birthdate) { Date.today - 66.years }

        it { expect(subject).to be_eligible }
      end
    end
  end

  describe "#out_of_scope?" do
    context "without birth date" do
      let(:birthdate) { nil }

      it { expect(subject).not_to be_out_of_scope }
    end

    context "with retirement year earlier than current year" do
      let(:birthdate) { Date.today - 85.years }

      it { expect(subject).to be_out_of_scope }
    end

    context "with retirement year later than current year" do
      let(:birthdate) { Date.today - 20.years }

      it { expect(subject).not_to be_out_of_scope }
    end
  end
end

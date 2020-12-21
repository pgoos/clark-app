# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::ElderlyDeductible do
  subject { described_class.new(1990, 199650) }

  let(:max) { 380000 }
  let(:percentage) { 8000 }

  before do
    create(:retirement_elderly_deductible, deductible_max_amount_cents: max, deductible_percentage: percentage)
  end

  describe "#call" do
    context "when gross * percentage above max" do
      let(:max) { 0 }
      let(:percentage) { 1000 }

      it { expect(subject.call).to eq(max) }
    end

    context "when gross * percentage below max" do
      let(:max) { 100_000 }
      let(:percentage) { 100 }

      it { expect(subject.call).to eq(1996.5) }
    end
  end
end

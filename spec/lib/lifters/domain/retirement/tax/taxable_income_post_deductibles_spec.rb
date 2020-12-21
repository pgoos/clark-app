# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Tax::TaxableIncomePostDeductibles do
  subject { described_class.(300000, 13_952, 18, 20000) }

  it { expect(subject).to eq 265482 }

  context "when calculation result is less than zero" do
    subject { described_class.(300000, 139520, 18, 200000) }

    it "returns zero" do
      expect(subject).to eq 0.0
    end
  end
end

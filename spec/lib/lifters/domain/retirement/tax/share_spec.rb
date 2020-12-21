# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Tax::Share do
  subject { described_class.(year) }

  before do
    create(:retirement_taxable_share, year: year, taxable_share_state_percentage: percentage)
  end

  context "when retirement year is valid" do
    let(:year) { 2052 }
    let(:percentage) { 5800 }

    describe "#percentage" do
      it { expect(subject).to eq 58 }
    end
  end

  context "when retirement year is not valid" do
    let(:year) { 3018 }
    let(:percentage) { 0 }

    describe "#percentage" do
      it { expect(subject).to eq 0 }
    end
  end
end

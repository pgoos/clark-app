# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::EligibilityPolicies::De::InformationProvidedPolicy do
  subject { described_class.new(situation) }

  let(:situation) { double :situation }

  let(:occupation) { "Occupation" }
  let(:gross_income) { true }

  before do
    allow(situation).to receive(:occupation).and_return occupation
    allow(situation).to receive(:yearly_gross_income?).and_return gross_income
  end

  context "when ocupation and yearly_gross_income are correct" do
    it { expect(subject.eligible?).to eq true }
  end

  context "when occupation isn't present" do
    let(:occupation) { "" }

    it { expect(subject.eligible?).to eq false }
  end

  context "when yearly_gross_income is false" do
    let(:gross_income) { false }

    it { expect(subject.eligible?).to eq false }
  end
end

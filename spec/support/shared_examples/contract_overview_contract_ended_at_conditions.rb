# frozen_string_literal: true

RSpec.shared_examples " a contract overview products with contract ended at conditions" do
  context "when contract end date is blank" do
    let!(:product) { setup_product contract_ended_at: nil }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when contract end date has not passed" do
    let!(:product) { setup_product contract_ended_at: Time.zone.now + 1.day }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when contract end date is today" do
    let!(:product) { setup_product contract_ended_at: Time.zone.now }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when contract end date has passed" do
    let!(:product) { setup_product contract_ended_at: 1.day.ago }

    it { expect(subject.all(mandate)).not_to include product }
  end
end

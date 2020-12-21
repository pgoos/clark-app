# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::FondsFinanz::Record do
  let(:exception_module) { Domain::Finance::PaymentImporter::FondsFinanz::Exceptions }

  context "validate!" do
    subject {
      described_class.new(settlement_date: "2019.10.23",
                          transaction_type: "initial_commission",
                          reference_number: "ery1212",
                          amount_cents: 10.0)
    }

    it "valid if has product" do
      subject.product = OpenStruct.new(name: "Product", id: 2)
      subject.validate!
      expect(subject).to be_valid
    end

    it "NOT valid if has NO product" do
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::ProductIsNotValid.to_s)
    end

    it "NOT valid if has NO settlement_date" do
      subject.instance_variable_set(:@settlement_date, nil)
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::SettlementDateInFileNotFound.to_s)
    end

    it "NOT valid if has NO transaction_type" do
      subject.instance_variable_set(:@transaction_type, nil)
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::TransactionTypeInFileIsNotCorrect.to_s)
    end

    it "NOT valid if has NO reference_number" do
      subject.instance_variable_set(:@reference_number, nil)
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::ReferanceNumberInFileIsNotCorrect.to_s)
    end

    it "NOT valid if has string amount_cents" do
      subject.instance_variable_set(:@amount_cents, "bad_value")
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::PaymentAmountIsNotCorrect.to_s)
    end

    it "NOT valid if has 0 amount_cents" do
      subject.instance_variable_set(:@amount_cents, 0.0)
      subject.validate!
      expect(subject).not_to be_valid
      expect(subject.errors).to include(exception_module::PaymentAmountCanNotBeZero.to_s)
    end
  end

  context "entity_id" do
    subject { described_class.new({}) }

    before do
      subject.product = OpenStruct.new(id: 123)
    end

    it "return product.id when entity_id called" do
      expect(subject.entity_id).to eq(subject.product.id)
    end
  end
end

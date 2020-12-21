# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::FondsFinanz::Exceptions do
  let(:parent_error) { Domain::Finance::PaymentImporter::PaymentImporterError }

  it "define FirstNameInFileNotFound" do
    expect(described_class::FirstNameInFileNotFound.superclass).to eq(parent_error)
  end

  it "define LastNameInFileNotFound" do
    expect(described_class::LastNameInFileNotFound.superclass).to be(parent_error)
  end

  it "define ProductNumberNotFound" do
    expect(described_class::ProductNumberNotFound.superclass).to be(parent_error)
  end

  it "define MandateNotFound" do
    expect(described_class::MandateNotFound.superclass).to be(parent_error)
  end

  it "define MandateNameNotMatch" do
    expect(described_class::MandateNameNotMatch.superclass).to be(parent_error)
  end

  it "define SettlementDateInFileNotFound" do
    expect(described_class::SettlementDateInFileNotFound.superclass).to be(parent_error)
  end

  it "define TransactionTypeInFileIsNotCorrect" do
    expect(described_class::TransactionTypeInFileIsNotCorrect.superclass).to be(parent_error)
  end

  it "define ReferanceNumberInFileIsNotCorrect" do
    expect(described_class::ReferanceNumberInFileIsNotCorrect.superclass).to be(parent_error)
  end

  it "define PaymentAmountIsNotCorrect" do
    expect(described_class::PaymentAmountIsNotCorrect.superclass).to be(parent_error)
  end

  it "define PaymentAmountCanNotBeZero" do
    expect(described_class::PaymentAmountCanNotBeZero.superclass).to be(parent_error)
  end

  it "define ProductIsNotValid" do
    expect(described_class::ProductIsNotValid.superclass).to be(parent_error)
  end
end

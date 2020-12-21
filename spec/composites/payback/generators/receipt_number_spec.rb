# frozen_string_literal: true

require "rails_helper"
require "composites/payback/generators/receipt_number"

RSpec.describe Payback::Generators::ReceiptNumber do
  subject(:receipt_number) { described_class.call(mandate_id, subject) }

  let(:mandate_id) { 111 }
  let(:subject) { FactoryBot.build_stubbed(:inquiry_category) }
  let(:subject_code) do
    Payback::Generators::ReceiptNumber::SUBJECT_CODES[subject.class.name.split("::").last]
  end

  it "generates receipt number" do
    expect(receipt_number).to eq("#{mandate_id}-#{subject.id}-#{subject_code}")
  end

  context "with incorrect subject" do
    let(:subject) { FactoryBot.build_stubbed(:inquiry) }

    it "throws error on unknown subject" do
      expect { receipt_number }.to raise_error("Unknown subject class Inquiry")
    end
  end
end

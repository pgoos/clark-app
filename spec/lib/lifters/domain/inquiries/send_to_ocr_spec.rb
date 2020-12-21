# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::SendToOCR do
  subject(:lifter) { described_class.new(inquiry_category) }

  let(:inquiry) { create(:inquiry, mandate: mandate) }
  let(:mandate) { create(:mandate) }
  let(:inquiry_category) {
    create(:inquiry_category, inquiry: inquiry, customer_documents_dismissed: false, documents: [document])
  }
  let(:document) { create(:document, :customer_upload) }
  let(:recognition_creation) { instance_double(Domain::OCR::RecognitionCreation) }

  describe "#send_to_ocr" do
    before do
      allow(recognition_creation).to receive(:create_recognition).and_return(true)
      allow(Domain::OCR::RecognitionCreation).to receive(:new)
        .with(document.asset, inquiry_category)
        .and_return(recognition_creation)
    end

    it "should return true" do
      expect(lifter.send_to_ocr).to be true
    end

    it "should update customer_documents_dismissed flag to true" do
      lifter.send_to_ocr

      expect(inquiry_category.reload.customer_documents_dismissed).to eq(true)
    end
  end
end

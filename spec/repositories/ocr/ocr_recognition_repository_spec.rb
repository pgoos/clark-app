# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::RecognitionRepository, :integration do
  describe "#find_by_task_id" do
    let(:document) { create(:document) }
    let!(:ocr_recognition1) { create(:ocr_recognition, :with_task_event, task_id: "id1") }
    let!(:ocr_recognition2) { create(:ocr_recognition, :with_task_event, task_id: "id2") }
    let!(:ocr_recognition3) { create(:ocr_recognition, :with_task_event, task_id: "id3") }
    let!(:ocr_recognition4) { create(:ocr_recognition) }

    it "finds the correct ProductRecognition" do
      expect(subject.find_by_task_id("id1")).to eq ocr_recognition1
      expect(subject.find_by_task_id("id2")).to eq ocr_recognition2

      ocr_recognition3.uploaded_document!(document, document.documentable)
      expect(subject.find_by_task_id("id3")).to eq ocr_recognition3

      expect(subject.find_by_task_id("id4")).to be_nil
    end
  end

  describe "#find_pending_recognitions" do
    let!(:ocr_recognition1) { create(:ocr_recognition, :with_product_validation_succeded) }
    let!(:ocr_recognition2) { create(:ocr_recognition, :with_product_validation_failed) }
    let!(:ocr_recognition3) do
      create(:ocr_recognition, :with_product_validation_succeded, :with_product_creation)
    end
    let!(:ocr_recognition4) do
      create(:ocr_recognition, :with_product_validation_failed, :with_product_creation)
    end

    it "finds the correct ocr_recognitions" do
      ocr_recognitions = subject.find_pending_recognitions
      expect(ocr_recognitions).to include(ocr_recognition1)
      expect(ocr_recognitions).to include(ocr_recognition2)
      expect(ocr_recognitions).not_to include(ocr_recognition3)
      expect(ocr_recognitions).not_to include(ocr_recognition4)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::TaskValidator, :integration do
  describe "#validate_task" do
    subject { described_class.new(task_id) }

    let(:inquiry_category) { create(:inquiry_category) }
    let(:task_id) { "task_id" }

    let(:payload_double) { instance_double(OCR::ContractDataMapper, task_id: task_id) }

    let!(:ocr_recognition) do
      create(:ocr_recognition,
             :with_document_event,
             :with_task_event,
             inquiry_category: inquiry_category, task_id: task_id)
    end

    let(:ocr_service_double) { instance_double(::OCR::Service) }
    let(:lifter_double) { instance_double(Domain::OCR::ProductRecognition) }

    before do
      allow(Domain::OCR::ProductRecognition).to receive(:new).and_return(lifter_double)
      allow(ocr_service_double).to receive(:task_data).and_return(payload_double)
      allow(lifter_double).to receive(:validate_product).with(payload_double).and_return(error)
      allow(ocr_service_double).to receive(:finish_processing)
    end

    context "when the validation has an error" do
      let(:error) { true }

      it "finishes processing with an error" do
        subject.validate_task(ocr_service: ocr_service_double)
        expect(ocr_service_double).to have_received(:finish_processing).with(task_id, error: false)
      end
    end

    context "when validation is successful" do
      let(:error) { false }

      it "finishes processing with an error" do
        subject.validate_task(ocr_service: ocr_service_double)
        expect(ocr_service_double).to have_received(:finish_processing).with(task_id, error: true)
      end
    end

    context "when recognition is null" do
      subject { described_class.new(unknown_task) }

      let(:unknown_task) { "unkown_task" }
      let(:error) { true }

      it "returns nil if task is not found" do
        subject.validate_task(ocr_service: ocr_service_double)
        expect(ocr_service_double).to have_received(:finish_processing).with(unknown_task, error: true)
      end
    end
  end
end

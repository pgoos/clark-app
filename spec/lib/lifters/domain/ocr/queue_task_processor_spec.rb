# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::QueueTaskProcessor, :integration do
  describe "#process_new_task" do
    let(:ocr_service_double) { instance_double(::OCR::Service) }
    let(:task_data) { instance_double(::OCR::ContractDataMapper, task_id: "task_id") }

    context "when not receiving a task" do
      it "does not call the job" do
        allow(ocr_service_double).to receive(:peek_finished_task).and_return(nil)
        allow(ValidateOCRTaskJob).to receive(:perform_later)

        subject.process_new_task(ocr_service: ocr_service_double)

        expect(ValidateOCRTaskJob).not_to have_received(:perform_later).with(task_data.task_id)
      end
    end

    context "when receiving one task" do
      it "calls the job properly" do
        allow(ocr_service_double).to receive(:peek_finished_task).and_return(task_data, nil)
        allow(ValidateOCRTaskJob).to receive(:perform_later)

        subject.process_new_task(ocr_service: ocr_service_double)

        expect(ValidateOCRTaskJob).to have_received(:perform_later).with(task_data.task_id)
      end
    end

    context "when receiving more than the limit tasks" do
      it "stops after the limit" do
        allow(ocr_service_double).to receive(:peek_finished_task).and_return(task_data)
        allow(ValidateOCRTaskJob).to receive(:perform_later)

        subject.process_new_task(ocr_service: ocr_service_double)

        expect(ValidateOCRTaskJob).to \
          have_received(:perform_later).with(task_data.task_id)
                                       .exactly(10).times
      end
    end
  end
end

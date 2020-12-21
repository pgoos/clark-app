# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateOCRTaskJob, type: :job do
  let(:ocr_recognition) { create(:ocr_recognition) }

  it "pushes the job in the correct queue" do
    expect {
      described_class.perform_later(ocr_recognition)
    }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  context "with valid ocr_recognition" do
    let(:document) { create(:document, documentable: create(:inquiry_category)) }
    let(:ocr_recognition) { create(:ocr_recognition, :with_document_event, document: document) }
    let(:lifter_double) { instance_double(Domain::OCR::ProductRecognition) }
    let(:task_id) { "task_id" }

    it "calls the lifter correctly" do
      expect(Domain::OCR::ProductRecognition).to \
        receive(:new).with(ocr_recognition).and_return(lifter_double)
      expect(lifter_double).to receive(:create_ocr_task).and_return task_id

      subject.perform(ocr_recognition.id)
    end
  end
end

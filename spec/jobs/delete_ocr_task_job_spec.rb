# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteOCRTaskJob, type: :job do
  let(:ocr_recognition) { create(:ocr_recognition, external_id: task_id) }
  let(:task_id) { "task_id" }

  it "pushes the job in the correct queue" do
    expect {
      described_class.perform_later(task_id)
    }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  context "with valid ocr_recognition" do
    let(:ocr_service_double) { instance_double(OCR::Service) }

    it "calls the lifter correctly" do
      expect(OCR::Service).to receive(:new).and_return(ocr_service_double)
      expect(ocr_service_double).to receive(:delete_task).with(task_id)
      subject.perform(ocr_recognition.id)
    end
  end
end

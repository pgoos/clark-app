# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidateOCRTaskJob, type: :job do
  let(:task_id) { "task_id" }

  it "pushes the job in the correct queue" do
    expect {
      described_class.perform_later(task_id)
    }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  context "when calling the correct class" do
    let(:task_validate_double) { instance_double(Domain::OCR::TaskValidator) }

    it "calls the correct class" do
      expect(Domain::OCR::TaskValidator).to \
        receive(:new).with(task_id).and_return(task_validate_double)

      expect(task_validate_double).to receive(:validate_task).and_return task_validate_double
      subject.perform(task_id)
    end
  end
end

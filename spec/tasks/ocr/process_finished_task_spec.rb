# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake ocr:process_finished_tasks", integration: true, type: :task do
  let(:queue_task_double) { instance_double(Domain::OCR::QueueTaskProcessor) }

  before do
    task.reenable

    allow(Domain::OCR::QueueTaskProcessor).to receive(:new).and_return(queue_task_double)
    allow(queue_task_double).to receive(:process_new_task)
  end

  context "with feature switch on" do
    it " calls the task processor" do
      expect(Features).to receive(:active?).with(Features::OCR).and_return(true)
      task.invoke
      expect(queue_task_double).to have_received(:process_new_task)
    end
  end

  context "with feature switch off" do
    it "does not calls the task processor" do
      expect(Features).to receive(:active?).with(Features::OCR).and_return(false)
      task.invoke
      expect(queue_task_double).not_to have_received(:process_new_task)
    end
  end
end

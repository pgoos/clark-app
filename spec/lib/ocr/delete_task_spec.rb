# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::DeleteTask, :vcr do
  describe "#call" do
    subject { OCR::DeleteTask.new(task_id) }

    let(:task_id) { "6b062f29" }
    let(:token) { "token" }

    context "when there is a task" do
      it "deletes the task data" do
        response = subject.call(token)
        expect(response.status).to eq 200
      end
    end
  end
end

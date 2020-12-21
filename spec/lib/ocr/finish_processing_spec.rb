# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::FinishProcessing, :vcr do
  describe "#call" do
    let(:token) { "token" }

    context "when there is a task" do
      subject { described_class.new(task_id, true) }

      let(:task_id) { "cb45477678eb461e88e2eca1dd484ce3" }

      it "finishes the task with success" do
        response = subject.call(token)
        expect(response.status).to eq 200
      end
    end

    context "when there is not a task" do
      subject { described_class.new("invalid_id", false) }

      it "receives a not found response" do
        response = subject.call(token)
        expect(response.status).to eq 404
      end
    end
  end
end

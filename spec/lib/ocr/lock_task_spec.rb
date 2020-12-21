# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::LockTask, :vcr do
  before { allow(Settings).to receive_message_chain(:ocr, :new_finished_task_timeout) { 10 } }

  describe "#call" do
    let(:token) { "token" }

    context "when there is a task" do
      it "receives the new task data" do
        response = subject.call(token)
        expect(response.status).to eq 200
        expect(response.parse["data"]["id"]).to eq "cb45477678eb461e88e2eca1dd484ce3"
      end
    end

    context "when there is not a task" do
      subject { described_class.new(state: "Supervisor") }

      it "receives a not found response" do
        response = subject.call(token)
        expect(response.status).to eq 404
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::GetTaskData, :vcr do
  subject { described_class.new(task_id).call(token) }

  let(:token) { "token" }

  context "when the information is successful" do
    let(:task_id) { "051ad464e8f74624b88254d74e9cc5e3" }

    it "receives the correct fields" do
      expect(subject.status).to eq 200
      expect(subject.parse["data"]["category"]).to eq "Dionera"
    end
  end

  context "when the token is invalid" do
    let(:token) { "invalid_token" }
    let(:task_id) { "051ad464e8f74624b88254d74e9cc5e3" }

    it "raises an error" do
      expect(subject.status).to eq 403
    end
  end

  context "when the task does not exist" do
    let(:task_id) { "invalid_task_id" }

    it "raises an error" do
      expect(subject.status).to eq 404
    end
  end
end

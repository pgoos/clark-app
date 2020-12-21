# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::CreateTask, :vcr do
  describe "#call" do
    subject { described_class.new(document) }

    let(:document) { create(:document) }

    let(:token) { "token" }

    context "when successful" do
      it "sends the correct form data" do
        response = subject.call(token)
        expect(response.parse["taskId"]).to eq "53269af6"
      end
    end

    context "with error" do
      let(:invalid_token) { "invalid_token" }

      it "raises an OCRAnalyzeError" do
        response = subject.call(token)
        expect(response.status).to eq 403
      end
    end
  end
end

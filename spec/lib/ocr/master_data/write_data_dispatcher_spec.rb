# frozen_string_literal: true

require "rails_helper"
require "ocr"

RSpec.describe OCR::MasterData::WriteDataDispatcher do
  subject { described_class.new(transaction_id, token, rows_limit) }

  def build_http_response(body, status)
    HTTP::Response.new(
      version: "1.1",
      status: status,
      headers: {"Content-Type" => "application/json"},
      body: body
    )
  end

  let(:rows_limit) { 3 }

  let(:transaction_id) { "transaction_id" }
  let(:token) { "token" }

  let(:table_name) { "table" }
  let(:data) { (1..10).to_a }

  let(:write_data_double) { instance_double(OCR::MasterData::WriteData) }

  before do
    allow(OCR::MasterData::WriteData).to receive(:new).and_return write_data_double
  end

  describe "#call" do
    context "when successful" do
      let(:body) { {errors: [{error: []}]}.to_json }
      let(:response) { build_http_response(body, 200) }

      before do
        allow(write_data_double).to receive(:call).and_return(response)
      end

      it "returns the correct argument" do
        response = subject.call(table_name, data)
        expect(response.success?).to eq true

        # (10.0 / 3.0).ceil == 4
        expect(write_data_double).to have_received(:call).exactly(4).times
        expect(OCR::MasterData::WriteData).to have_received(:new).with(transaction_id, table_name, [1, 2, 3])
        expect(OCR::MasterData::WriteData).to have_received(:new).with(transaction_id, table_name, [4, 5, 6])
        expect(OCR::MasterData::WriteData).to have_received(:new).with(transaction_id, table_name, [7, 8, 9])
        expect(OCR::MasterData::WriteData).to have_received(:new).with(transaction_id, table_name, [10])
      end
    end

    context "with an error" do
      let(:body) { {errors: [{error: []}]}.to_json }
      let(:success_response) { build_http_response(body, 200) }

      let(:error_body1) { {errors: [{error: ["Constraint 1 violated"]}]}.to_json }
      let(:error_response1) { build_http_response(error_body1, 400) }

      let(:error_body2) { {errors: [{error: ["Constraint 2 violated"]}]}.to_json }
      let(:error_response2) { build_http_response(error_body2, 400) }

      before do
        allow(write_data_double).to receive(:call).ordered.and_return(
          success_response, error_response1, success_response, error_response2
        )
      end

      it "returns the correct errors" do
        response = subject.call(table_name, data)
        expect(response.success?).to eq false
        expect(response.errors).to match_array [[["Constraint 1 violated"]], [["Constraint 2 violated"]]]
      end
    end
  end
end

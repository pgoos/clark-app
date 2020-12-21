# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::Service do
  let(:token) { "token" }
  let(:authentication_double) { instance_double(OCR::Authentication) }

  let(:authentication_response) do
    HTTP::Response.new(
      version: "1.1",
      status: 200,
      headers: {"Content-Type" => "application/json"},
      body: {token: "token"}.to_json
    )
  end

  def build_http_response(body, status)
    HTTP::Response.new(
      version: "1.1",
      status: status,
      headers: {"Content-Type" => "application/json"},
      body: body
    )
  end

  before do
    allow(OCR::Authentication).to receive(:new).and_return authentication_double
    allow(authentication_double).to receive(:call).and_return authentication_response
    allow(Settings).to receive_message_chain(:ocr, :master_data_rows_limit) { 8000 }
    allow(Settings).to receive_message_chain(:ocr, :master_data_limit_task) { 8 }
  end

  context "with an invalid token" do
    let(:document) { build_stubbed(:document) }

    let(:authentication_response) { build_http_response("null", 403) }

    it "raises an error" do
      expect { subject.create_task(document) }.to raise_error do |error|
        expect(error.status).to eq 403
      end
    end
  end

  describe "#create_task" do
    let(:response) { build_http_response(body, status) }

    let(:create_task_double) { instance_double(OCR::CreateTask, call: response) }
    let(:document) { build_stubbed(:document) }

    before do
      allow(OCR::CreateTask).to receive(:new).with(document).and_return create_task_double
    end

    context "when successful" do
      let(:new_task_id) { "10" }
      let(:body) { {"taskId" => new_task_id}.to_json }
      let(:status) { 200 }

      it "returns the correct" do
        task_id = subject.create_task(document)
        expect(task_id).to eq new_task_id
      end
    end

    context "with an error" do
      let(:body) { "null" }
      let(:status) { 404 }

      it "raises an error" do
        expect { subject.create_task(document) }.to raise_error do |error|
          expect(error.status).to eq status
          expect(error.body).to eq body
          expect(error.message).to eq "Create task with document #{document.id} failed"
          expect(error).to be_a(OCR::ApiError)
        end
      end
    end
  end

  describe "#task_data" do
    let(:get_task_double) { instance_double(OCR::GetTaskData, call: response) }
    let(:task_id) { "10" }

    let(:response) { build_http_response(body, status) }

    before do
      allow(OCR::GetTaskData).to receive(:new).with(task_id).and_return get_task_double
    end

    context "when successful" do
      let(:body) { file_fixture("ocr/simple_info_response.json").read }
      let(:status) { 200 }

      it "returns the the api response" do
        wrapper = subject.task_data(task_id)
        expect(wrapper.insurance_number).to eq "709/237527-F-14"
        expect(wrapper.task_id).to eq "fcc780c9"
        expect(wrapper.premium_period).to eq "jährlich"
        expect(wrapper.premium_price).to eq 73.0
        expect(wrapper.contract_start).to eq "2018-09-14".to_date
        expect(wrapper.contract_end).to eq "2019-09-14".to_date
        expect(wrapper.mandate_id).to eq "1163065"

        expect(wrapper.manual_verified_fields).to \
          eq(%w[MANDATE_ID])
      end
    end

    context "with an error" do
      let(:body) { "null" }
      let(:status) { 404 }

      it "raises an error" do
        expect { subject.task_data(task_id) }.to raise_error do |error|
          expect(error.status).to eq status
          expect(error.body).to eq body
          expect(error.message).to eq "Couldn't fetch task #{task_id}"
          expect(error).to be_a(OCR::ApiError)
        end
      end
    end
  end

  describe "#peek_finished_task" do
    let(:response) { build_http_response(body, status) }

    let(:lock_task_double) { instance_double(OCR::LockTask, call: response) }

    before do
      allow(OCR::LockTask).to receive(:new).and_return lock_task_double
    end

    context "when successful" do
      let(:body) { file_fixture("ocr/simple_info_response.json").read }
      let(:status) { 200 }

      it "returns the correct data" do
        task_data = subject.peek_finished_task
        expect(task_data.insurance_number).to eq "709/237527-F-14"
        expect(task_data.task_id).to eq "fcc780c9"
      end
    end

    context "when not found" do
      let(:body) { "null" }
      let(:status) { 404 }

      it "returns a nil object" do
        task_data = subject.peek_finished_task
        expect(task_data).to be_nil
      end
    end

    context "when there is an error" do
      let(:body) { "null" }
      let(:status) { 403 }

      it "returns an error object" do
        expect { subject.peek_finished_task }.to raise_error do |error|
          expect(error.status).to eq status
          expect(error.body).to eq body
          expect(error.message).to eq "Peek new task from queue failed"
          expect(error).to be_a(OCR::ApiError)
        end
      end
    end
  end

  describe "#task_link" do
    let(:task_id) { "task_id" }

    it "returns the correct link" do
      url = "#{Settings.insiders.web_host}#{Settings.insiders.web_verifier_url % task_id}"
      expect(subject.task_link(task_id)).to eq url
    end
  end

  describe "#finish_processing" do
    let(:response) { build_http_response(body, status) }

    let(:finish_processing_double) { instance_double(OCR::FinishProcessing, call: response) }
    let(:task_id) { "task_id" }

    before do
      allow(OCR::FinishProcessing).to receive(:new).and_return finish_processing_double
    end

    context "when successful" do
      let(:body) { "" }
      let(:status) { 200 }

      it "returns the correct" do
        response = subject.finish_processing("task_id", error: false)
        expect(response).to be_nil
        expect(OCR::FinishProcessing).to have_received(:new).with(task_id, false)
      end
    end

    context "when there is an error" do
      let(:body) { "null" }
      let(:status) { 500 }

      it "returns an error object" do
        expect { subject.finish_processing(task_id, error: false) }.to raise_error do |error|
          expect(error.status).to eq status
          expect(error.body).to eq body
          expect(error.message).to eq "Could not finish task #{task_id} with error false"
          expect(error).to be_a(OCR::ApiError)
        end
      end
    end
  end

  describe "#write_master_data" do
    let(:data) do
      [
        %w[data_01 data_02 data_03],
        %w[data_11 data_12 data_13]
      ]
    end

    let(:table) { "table" }
    let(:columns) { %w[columns1 column2] }

    let(:transaction_id) { "transaction_id" }
    let(:transaction_body) { {transactionId: transaction_id}.to_json }
    let(:transaction_response) { build_http_response(transaction_body, 200) }
    let(:create_transaction_double) { instance_double(OCR::MasterData::CreateTransaction, call: transaction_response) }

    let(:write_body) { {errors: []}.to_json }
    let(:write_response) { build_http_response(write_body, 200) }
    let(:write_data_double) { instance_double(OCR::MasterData::WriteData, call: write_response) }

    let(:commit_response) { build_http_response(nil, 200) }
    let(:commit_double) { instance_double(OCR::MasterData::Commit, call: commit_response) }

    let(:rollback_response) { build_http_response(nil, 200) }
    let(:rollback_double) { instance_double(OCR::MasterData::Rollback, call: rollback_response) }

    before do
      allow(OCR::MasterData::CreateTransaction).to receive(:new).and_return(create_transaction_double)
      allow(OCR::MasterData::WriteData).to receive(:new).and_return(write_data_double)
      allow(OCR::MasterData::Commit).to receive(:new).and_return(commit_double)
      allow(OCR::MasterData::Rollback).to receive(:new).and_return(rollback_double)
    end

    context "when failed" do
      context "with transaction failing" do
        let(:body) { "null" }
        let(:status) { 500 }
        let(:transaction_response) { build_http_response(body, status) }

        it "does not call write_data nor commit" do
          expect { subject.write_master_data(table, columns, data) }.to raise_error do |error|
            expect(error.message).to eq("Unable to start transaction")
            expect(error).to be_a(OCR::ApiError)
          end

          expect(OCR::MasterData::CreateTransaction).to have_received(:new).with(table, columns, false)
          expect(create_transaction_double).to have_received(:call)
          expect(write_data_double).not_to receive(:call)
          expect(commit_double).not_to receive(:call)
          expect(rollback_double).not_to receive(:call)
        end
      end

      context "with writing data failing" do
        context "when the response is not a JSON" do
          let(:status) { 400 }
          let(:body) { "null" }
          let(:write_response) { build_http_response(body, status) }

          it "rollbacks the transaction" do
            expect { subject.write_master_data(table, columns, data) }.to raise_error do |error|
              expect(error.message).to eq("Update master_data failed")
              expect(error).to be_a(OCR::ApiError)
              expect(error.raven_context[:extra][:body]).to eq(["null"])
            end

            expect(OCR::MasterData::WriteData).to have_received(:new).with(transaction_id, table, data)
            expect(write_data_double).to have_received(:call)
            expect(rollback_double).to have_received(:call)
            expect(commit_double).not_to have_received(:call)
          end
        end

        context "when the response is an array of errors" do
          let(:error_description) { "Error in constraint" }
          let(:status) { 400 }
          let(:body) { {errors: [{error: error_description}]}.to_json }
          let(:write_response) { build_http_response(body, status) }

          it "raises the correct data" do
            expect { subject.write_master_data(table, columns, data) }.to raise_error do |error|
              expect(error.message).to eq("Update master_data failed")
              expect(error).to be_a(OCR::ApiError)
              expect(error.raven_context[:extra][:body]).to eq([[error_description]])
            end
          end
        end
      end

      context "with commit failing" do
        let(:status) { 400 }
        let(:body) { "null" }
        let(:commit_response) { build_http_response(body, status) }

        it "rollbacks the if the commit is wrong" do
          expect { subject.write_master_data(table, columns, data) }.to raise_error do |error|
            expect(error.message).to eq("Commit transaction #{transaction_id} failed")
            expect(error).to be_a(OCR::ApiError)
          end

          expect(OCR::MasterData::Commit).to have_received(:new).with(transaction_id)
          expect(write_data_double).to have_received(:call)
          expect(rollback_double).to have_received(:call)
          expect(commit_double).to have_received(:call)
        end
      end
    end

    context "when successfull" do
      before do
        allow(OCR::MasterData::WriteData).to \
          receive(:new).and_return(write_data_double)
      end

      it "calls write_data and commit" do
        subject.write_master_data(table, columns, data)
        expect(write_data_double).to have_received(:call)
        expect(rollback_double).not_to have_received(:call)
        expect(commit_double).to have_received(:call)
      end
    end
  end

  describe "#delete_task" do
    let(:response) { build_http_response(body, status) }

    let(:delete_task_double) { instance_double(OCR::DeleteTask, call: response) }
    let(:task_id) { "task_id" }

    before do
      allow(OCR::DeleteTask).to receive(:new).and_return delete_task_double
    end

    context "when successful" do
      let(:body) { "" }
      let(:status) { 200 }

      it "returns the correct" do
        response = subject.delete_task("task_id")
        expect(response).to be_nil
        expect(OCR::DeleteTask).to have_received(:new).with(task_id)
      end
    end

    context "when the task does not exist" do
      let(:body) { "" }
      let(:status) { 404 }

      it "does not raise an error" do
        response = subject.delete_task("task_id")
        expect(response).to be_nil
        expect(OCR::DeleteTask).to have_received(:new).with(task_id)
      end
    end

    context "when there is an error" do
      let(:body) { "null" }
      let(:status) { 500 }

      it "returns an error object" do
        expect { subject.delete_task(task_id) }.to raise_error do |error|
          expect(error.status).to eq status
          expect(error.body).to eq body
          expect(error.message).to eq "Could not delete task #{task_id}"
          expect(error).to be_a(OCR::ApiError)
        end
      end
    end
  end
end

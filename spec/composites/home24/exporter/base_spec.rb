# frozen_string_literal: true

require "rails_helper"
require "composites/home24/exporter/base"

RSpec.describe Home24::Exporter::Base, :integration do
  subject { described_class.new }

  let(:customer_repo) {
    double(
      Home24::Repositories::CustomerRepository,
      find: customer,
      save_export_state: true
    )
  }
  let(:order_id) { "101231235619" }
  let(:queue_message) {
    OpenStruct.new(message_id: "12345", receipt_handle: "test",
                   body: { "mandate_id" => 1, "order_id" => order_id }.to_json)
  }

  let(:sftp_client) { double(upload: true) }
  let(:sqs_client) { double(receive_message: double(messages: []), delete_message: true) }
  let(:customer) { double(home24_data: { "export_state" => "initiated" }) }

  before do
    allow(Home24::Exporter::Logger).to receive(:error).and_return(true)
    allow(Home24::Exporter::Logger).to receive(:info).and_return(true)
    allow(Home24::Exporter::Sftp::FakeClient).to receive(:new).and_return(sftp_client)
    allow(Home24::Factories::Sqs::Client).to receive(:build).and_return(sqs_client)
    allow(Home24::Repositories::CustomerRepository).to receive(:new).and_return(customer_repo)
  end

  context "when there is not any message in queue" do
    it "fetches messages using sqs client" do
      expect(sqs_client).to receive(:receive_message).with(10)

      subject.perform
    end

    it "doesn't initiate upload" do
      expect(sftp_client).not_to receive(:upload)

      subject.perform
    end
  end

  context "when there are messages in the queue" do
    let(:generated_csv_file) { double(name: "test.csv", content: "") }
    let(:csv_builder) { double(generate: generated_csv_file) }
    let(:zip_file) { double(name: "test.csv") }
    let(:zip_builder) { double(generate: zip_file) }

    before do
      allow(subject).to receive(:fetch_messages).and_return([queue_message])
      allow(Home24::Exporter::Builders::Csv).to receive(:new).and_return(csv_builder)
      allow(Home24::Exporter::Builders::Zip).to receive(:new).and_return(zip_builder)
    end

    it "generates csv file with correct data" do
      expect(Home24::Exporter::Builders::Csv).to receive(:new).with("#{order_id}.csv")
      expect(csv_builder).to receive(:generate).with(JSON.parse(queue_message.body))

      subject.perform
    end

    it "generates zip file with csv files" do
      expect(zip_builder).to receive(:generate).with([generated_csv_file])

      subject.perform
    end

    it "initiates upload using Sftp client" do
      expect(sftp_client).to receive(:upload).with(zip_file.name, zip_file.name.split("/").last)

      subject.perform
    end

    it "updates the export state for customer" do
      expect(customer_repo)
        .to receive(:save_export_state).with(JSON.parse(queue_message.body)["mandate_id"], "completed")

      subject.perform
    end

    it "deletes message from queue" do
      expect(sqs_client).to receive(:delete_message).with(queue_message.receipt_handle)

      subject.perform
    end

    context "when there is an error thrown while uploading" do
      before do
        allow(sftp_client).to receive(:upload).and_raise(StandardError)
      end

      it "logs the error" do
        expect(Home24::Exporter::Logger).to receive(:error)

        subject.perform
      end

      it "doesn't update the export state" do
        expect(customer_repo).not_to receive(:save_export_state)

        subject.perform
      end

      it "doesn't delete message from queue" do
        expect(sqs_client).not_to receive(:delete_message)

        subject.perform
      end
    end

    context "When customer doesn't exists" do
      before do
        allow(customer_repo).to receive(:find).and_return(nil)
      end

      it "doesn't generate csv file" do
        expect(Home24::Exporter::Builders::Csv).not_to receive(:new)

        subject.perform
      end

      it "doesn't initiate upload" do
        expect(sftp_client).not_to receive(:upload)

        subject.perform
      end

      it "doesn't update the export state" do
        expect(customer_repo).not_to receive(:save_export_state)

        subject.perform
      end

      it "deletes message from queue" do
        expect(sqs_client).to receive(:delete_message).with(queue_message.receipt_handle)

        subject.perform
      end
    end

    context "when customer is already exported" do
      before do
        allow(customer).to receive(:home24_data).and_return("export_state" => "completed")
      end

      it "doesn't generate csv file" do
        expect(Home24::Exporter::Builders::Csv).not_to receive(:new)

        subject.perform
      end

      it "doesn't initiate upload" do
        expect(sftp_client).not_to receive(:upload)

        subject.perform
      end

      it "doesn't update the export state" do
        expect(customer_repo).not_to receive(:save_export_state)

        subject.perform
      end

      it "deletes message from queue" do
        expect(sqs_client).to receive(:delete_message).with(queue_message.receipt_handle)

        subject.perform
      end
    end

    it "reports any exceptions to the sentry instance for partners" do
      allow_any_instance_of(described_class).to receive(:fetch_messages).and_raise("mock exception")
      expect(Platform::RavenPartners.instance.sentry_logger).to receive(:capture_exception)
      subject.perform
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdvertisementPerformanceLogImportJob, type: :job do
  let(:job_queue) { "advertisement_performance_log_import" }
  let(:admin) { create(:admin) }
  let(:starting_from) { "2020-03-01" }
  let(:ending_at) { "2020-03-30" }
  let(:ad_provider) { "Facebook" }
  let(:brand) { "true" }
  let(:document) { double(Document, id: 1) }
  let(:importer_result) do
    Domain::Cost::AdvertisementPerformanceLog::Importer::Result.new(3, 0, [])
  end
  let(:importer) { double(Domain::Cost::AdvertisementPerformanceLog::Importer::Base, import!: importer_result) }
  let(:mailer) { double(OutboundChannels::Mailer, send_plain_text: true) }
  let(:data) do
    {
      document_id: document.id,
      starting_from: starting_from,
      ending_at: ending_at,
      ad_provider: ad_provider,
      brand: brand,
      admin_email: admin.email
    }
  end

  before do
    allow(Domain::Cost::AdvertisementPerformanceLog::Importer::Base)
      .to receive(:new).and_return(importer)

    allow(OutboundChannels::Mailer).to receive(:new).and_return(mailer)
  end

  it { is_expected.to be_a(ClarkJob) }

  it "should append to the queue 'advertisement_performance_log_import'" do
    expect(subject.queue_name).to eq(job_queue)
  end

  it "enqueues the job on the 'advertisement_performance_log_import' queue" do
    expect {
      described_class.perform_later(data)
    }.to have_enqueued_job.with(data).on_queue(job_queue)
  end

  context "when there is not any exception thrown" do
    it "initialize the importer instance with the parameters passed" do
      expect(Domain::Cost::AdvertisementPerformanceLog::Importer::Base)
        .to receive(:new).with(
          data[:document_id],
          data[:starting_from],
          data[:ending_at],
          data[:ad_provider],
          data[:brand]
        )

      subject.perform(data)
    end

    it "imports the entries by calling import! method at importer instance" do
      expect(importer).to receive(:import!)

      subject.perform(data)
    end

    it "should notify the admin that import was successful with the logs info" do
      message = OpenStruct.new(subject: "Advertisement Performance Logs import processing Completed!",
                               body: importer_result.message_format)

      expect(mailer).to receive(:send_plain_text).with(admin.email, admin.email, message)

      subject.perform(data)
    end
  end

  context "when there is an exception thrown" do
    let(:error_message) { "There is no parser for document type JSON" }

    before do
      allow(importer).to receive(:import!).and_raise(StandardError, error_message)
    end

    it "notifies the admin with the error occured" do
      message = OpenStruct.new(subject: "Advertisement Performance Logs import processing Failed!",
                               body: "(Error) #{error_message}")

      expect(mailer).to receive(:send_plain_text).with(admin.email, admin.email, message)

      subject.perform(data)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::RecognitionCreation, :integration do
  describe "#create_recognition" do
    let(:document_file) do
      Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "assets", "mandate.pdf"))
    end

    context "when it is valid" do
      subject { described_class.new(document_file) }

      it "creates a document and the correct events" do
        allow(CreateOCRTaskJob).to receive(:perform_later)
        recognition = subject.create_recognition
        expect(Document.last.document_type.key).to eq "POLICY"
        expect(Document.last.documentable).to eq recognition

        events = recognition.events
        expect(events.size).to eq 1

        expect(events.first.event_type).to eq OCR::Event::DOCUMENT_UPLOADED
        expect(events.first.payload["document_id"]).to eq recognition.reload.document.id

        expect(CreateOCRTaskJob).to have_received(:perform_later).with(recognition.reload.id)
      end
    end

    context "with an inquiry_category" do
      subject { described_class.new(document_file, inquiry_category) }

      let(:inquiry_category) { create(:inquiry_category) }

      it "creates the correct event" do
        recognition = subject.create_recognition
        events = recognition.events
        expect(events.size).to eq 1

        expect(events.first.event_type).to eq OCR::Event::DOCUMENT_UPLOADED
        expect(events.first.payload["inquiry_category_id"]).to eq inquiry_category.id
      end
    end

    context "with an exception" do
      subject { described_class.new(nil) }

      it "does not create a document" do
        expect { subject.create_recognition }.to raise_error ActiveRecord::RecordInvalid
        expect(Document.count).to eq 0
      end
    end
  end
end

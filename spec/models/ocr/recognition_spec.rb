# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::Recognition do
  it { is_expected.to have_many(:events).dependent(:destroy) }
  it { is_expected.to have_one(:document).dependent(:destroy) }

  describe "#uploaded_document!" do
    let(:document) { build_stubbed(:document) }
    let(:inquiry_category) { build_stubbed(:inquiry_category) }

    context "with inquiry category" do
      it "has the correct event" do
        subject.uploaded_document!(document, inquiry_category)

        events = subject.events
        expect(events.size).to eq 1

        event = events.first
        expect(event.event_type).to eq OCR::Event::DOCUMENT_UPLOADED
        expect(event.payload["document_id"]).to eq document.id
        expect(event.payload["inquiry_category_id"]).to eq inquiry_category.id
        expect(event.payload["upload_type"]).to eq "with_inquiry_category"
      end
    end

    context "without inquiry category" do
      it "has the correct event" do
        subject.uploaded_document!(document)

        events = subject.events
        expect(events.size).to eq 1

        event = events.first
        expect(event.event_type).to eq OCR::Event::DOCUMENT_UPLOADED
        expect(event.payload["upload_type"]).to eq "batch_upload"
      end
    end
  end

  describe "#inquiry_category" do
    let(:document) { build_stubbed(:document) }
    let(:inquiry_category) { create(:inquiry_category) }

    context "with inquiry category" do
      it "has the InquiryCategory object" do
        subject.uploaded_document!(document, inquiry_category)
        expect(subject.inquiry_category).to eq inquiry_category
      end
    end

    context "without inquiry_category" do
      it "returns nil" do
        subject.uploaded_document!(document)
        expect(subject.inquiry_category).to be_nil
      end
    end
  end

  describe "#started_recognition!" do
    let(:task_id) { "task_id" }

    it "has the correct event" do
      subject.started_recognition!(task_id)

      events = subject.events
      expect(events.size).to eq 1

      event = events.first
      expect(event.event_type).to eq OCR::Event::OCR_RECOGNITION_STARTED
      expect(event.payload["task_id"]).to eq task_id
    end
  end

  describe "#validated_product_with_errors!" do
    let(:errors) { {"plan" => "must be present"} }
    let(:payload) { "ocr_payload" }
    let(:product_attributes) { {"number" => "Insurance number"} }
    let(:verified_fields) { %w[PLAN_ID NUMBER] }

    it "has the correct event" do
      subject.validated_product_with_errors!(
        errors,
        ocr_payload: payload,
        product_attributes: product_attributes,
        manually_corrected_fields: verified_fields
      )

      events = subject.events
      expect(events.size).to eq 1

      event = events.first
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_FAILED
      expect(event.payload).to \
        eq("errors" => errors, "ocr_payload" => payload,
           "product_attributes" => product_attributes,
           "manually_corrected_fields" => verified_fields)
    end
  end

  describe "#validated_product_successfully!" do
    let(:attributes) { {"plan_id" => 1} }
    let(:payload) { "ocr_payload" }

    it "has the correct event" do
      subject.validated_product_successfully!(attributes, ocr_payload: payload)

      events = subject.events
      expect(events.size).to eq 1

      event = events.first
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_SUCCEDED
      expect(event.payload).to \
        eq("product_attributes" => attributes, "ocr_payload" => payload, "manually_corrected_fields" => [])
    end
  end

  describe "#created_product_successfully!" do
    let(:product) { build_stubbed(:product) }

    it "has the correct event" do
      subject.created_product_successfully!(product)

      events = subject.events
      expect(events.size).to eq 1

      event = events.first
      expect(event.event_type).to eq OCR::Event::PRODUCT_CREATION_SUCCEDED
      expect(event.payload).to eq("product_id" => product.id)
    end
  end

  describe "#started_product_validation!" do
    let(:task_id) { "task_id" }

    it "has the correct event" do
      subject.started_product_validation!(task_id)

      events = subject.events
      expect(events.size).to eq 1

      event = events.first
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_STARTED
      expect(event.payload).to eq("task_id" => task_id)
    end
  end

  describe "#find_event" do
    let(:ocr_recognition) do
      create(:ocr_recognition, :with_product_validation_failed, :with_product_validation_succeded)
    end

    it "returns the correct events" do
      event = ocr_recognition.find_event(OCR::Event::PRODUCT_VALIDATION_SUCCEDED)
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_SUCCEDED

      event = ocr_recognition.find_event(OCR::Event::PRODUCT_VALIDATION_FAILED)
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_FAILED

      event = ocr_recognition.find_event(
        OCR::Event::PRODUCT_VALIDATION_FAILED, OCR::Event::PRODUCT_VALIDATION_SUCCEDED
      )
      expect(event.event_type).to eq OCR::Event::PRODUCT_VALIDATION_SUCCEDED

      event = ocr_recognition.find_event(OCR::Event::OCR_RECOGNITION_STARTED)
      expect(event).to be_nil
    end
  end

  describe "#product_attributes" do
    let(:ocr_recognition) { create(:ocr_recognition) }
    let(:product_attributes) { {"number" => "Insurance Number"} }
    let(:other_product_attributes) { {"number" => "Other number"} }

    it "returns the correct product_attributes when successfully" do
      ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
      expect(ocr_recognition.product_attributes).to eq product_attributes
    end

    it "returns the correct product attributes with a failed" do
      ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
      ocr_recognition.validated_product_with_errors!(
        ["Plan not found"], ocr_payload: "payload", product_attributes: other_product_attributes
      )
      expect(ocr_recognition.product_attributes).to eq other_product_attributes
    end
  end

  describe "#successful_validation?" do
    let(:ocr_recognition) { create(:ocr_recognition) }
    let(:product_attributes) { {"number" => "Insurance Number"} }

    it "returns the correct product_attributes when successfully" do
      expect(ocr_recognition.successful_validation?).to eq false
      ocr_recognition.validated_product_with_errors!(["Plan not found"], ocr_payload: "payload")
      expect(ocr_recognition.successful_validation?).to eq false
      ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
      expect(ocr_recognition.successful_validation?).to eq true
    end
  end
end

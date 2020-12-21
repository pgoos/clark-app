# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::ProductRecognition, :integration do
  describe "#create_ocr_task" do
    subject { described_class.new(ocr_recognition) }

    let(:ocr_service_double) { instance_double(::OCR::Service) }
    let(:ocr_recognition) { create(:ocr_recognition, :with_document_event, document: document) }

    let(:inquiry_category) { create(:inquiry_category) }
    let(:document) { create(:document, documentable: inquiry_category) }

    context "when valid" do
      let(:task_id) { "task_id" }

      before { allow(ocr_service_double).to receive(:create_task).and_return(task_id) }

      it "creates a new event" do
        subject.create_ocr_task(ocr_service: ocr_service_double)

        events = ocr_recognition.events
        expect(events.size).to eq 2
        expect(events.last.event_type).to eq OCR::Event::OCR_RECOGNITION_STARTED
        expect(events.last.payload["task_id"]).to eq task_id

        expect(ocr_recognition.reload.external_id).to eq task_id
      end
    end

    context "when it is invalid" do
      let(:error) { ::OCR::ApiError.new("error") }

      before { allow(ocr_service_double).to receive(:create_task).and_raise(error) }

      it "does not create a new event" do
        expect { subject.create_ocr_task(ocr_service: ocr_service_double) }.to raise_error(error)

        expect(ocr_recognition.events.size).to eq 1
      end
    end
  end

  describe "#validate_product" do
    subject { described_class.new(ocr_recognition) }

    let(:payload_data) { JSON.parse(file_fixture("ocr/simple_info_response.json").read) }
    let(:payload) { OCR::ContractDataMapper.new(payload_data) }

    let(:inquiry_category) { create(:inquiry_category) }

    let(:ocr_recognition) do
      create(:ocr_recognition, :with_document_event, inquiry_category: inquiry_category)
    end

    let(:ocr_service_double) { instance_double(OCR::Service) }

    before do
      allow(ocr_service_double).to receive(:finish_processing)
    end

    context "when valid" do
      let!(:plan) do
        create(
          :plan,
          ident: payload.plan_ident,
          company: inquiry_category.inquiry.company,
          category: inquiry_category.category
        )
      end

      context "with valid product payload" do
        it "saves the correct events" do
          success = subject.validate_product(payload)
          events = ocr_recognition.events
          expect(success).to be_truthy

          expect(events.size).to eq 3
          expect(events[1].event_type).to eq OCR::Event::PRODUCT_VALIDATION_STARTED
          expect(events[1].payload["task_id"]).to eq payload.task_id

          expect(events[2].event_type).to eq OCR::Event::PRODUCT_VALIDATION_SUCCEDED
          expect(events[2].payload["product_attributes"]["plan_id"]).to eq plan.id
          expect(events[2].payload["ocr_payload"]).to eq payload_data
          expect(events[2].payload["manually_corrected_fields"]).to \
            eq(%w[MANDATE_ID])
        end

        context "without inquiry_category" do
          let(:ocr_recognition) do
            create(:ocr_recognition, :with_document_event_without_inquiry_category)
          end

          it "saves the product with an empty inquiry" do
            success = subject.validate_product(payload)
            events = ocr_recognition.events
            expect(success).to be_truthy

            expect(events.size).to eq 3

            expect(events[2].event_type).to eq OCR::Event::PRODUCT_VALIDATION_SUCCEDED
            expect(events[2].payload["product_attributes"]["inquiry_id"]).to be_nil
          end
        end
      end
    end

    context "with invalid product payload" do
      it "adds correct events" do
        success = subject.validate_product(payload)
        events = ocr_recognition.events
        expect(success).to be_falsey

        expect(events.size).to eq 3

        expect(events[1].event_type).to eq OCR::Event::PRODUCT_VALIDATION_STARTED
        expect(events[1].payload["task_id"]).to eq payload.task_id

        expect(events[2].event_type).to eq OCR::Event::PRODUCT_VALIDATION_FAILED
        message = "#{I18n.t('attributes.plan')} #{I18n.t('errors.messages.required')}"
        expect(events[2].payload["errors"].first).to eq message
        expect(events[2].payload["ocr_payload"]).to eq payload_data
        expect(events[2].payload["product_attributes"]["number"]).to eq payload.insurance_number
        expect(events[2].payload["manually_corrected_fields"]).to eq payload.manual_verified_fields
      end
    end
  end
end

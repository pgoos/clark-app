# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::Projection::EventDispatcher, :integration do
  describe "#after_create" do
    let(:recognition) { create(:ocr_recognition) }
    let(:task_id) { "task_id" }

    before do
      Wisper.clear
      OCR::Event.subscribe(described_class, async: true)
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    context "when the event is created" do
      it "creates the correct projection" do
        expect { recognition.started_recognition!(task_id) }.to \
          change { OCR::BIProjection.count }.by(1)

        projection = OCR::BIProjection.find_by(recognition: recognition)
        expect(projection.recognition).to eq recognition
        expect(projection.started_at).to be_within(2.seconds).of(recognition.events.first.created_at)
      end
    end

    context "with validation failed events" do
      context "when there is not a recognition started event" do
        it "does not create the recognition" do
          expect { recognition.validated_product_with_errors!(["error"], ocr_payload: "payload") }.to \
            change { OCR::BIProjection.count }.by(0)
        end
      end

      context "when there is a recognition instance" do
        it "updates the failed related columns" do
          recognition.started_recognition!(task_id)

          projection = OCR::BIProjection.find_by(recognition: recognition)
          expect(projection.failed_count).to eq(0)

          recognition.validated_product_with_errors!(
            ["error"],
            ocr_payload: "payload",
            manually_corrected_fields: ["PLAN_ID"]
          )
          failed_at = projection.reload.failed_validation_at
          last_event_at = recognition.reload.events.last.created_at

          expect(failed_at).to be_within(2.seconds).of(last_event_at)
          expect(projection.failed_count).to eq(1)
          expect(projection.verification_required).to eq(true)
          expect(projection.verified_fields).to eq(["PLAN_ID"])

          recognition.validated_product_with_errors!(["new error"], ocr_payload: "payload")
          expect(projection.reload.failed_count).to eq(2)
          expect(projection.verification_required).to eq(false)
          expect(projection.verified_fields).to eq([])
        end
      end
    end

    context "with validation succeded events" do
      context "when there is a successful validation" do
        it "saves the related columns when there is a payload" do
          recognition.started_recognition!(task_id)
          projection = OCR::BIProjection.find_by(recognition: recognition)

          recognition.validated_product_successfully!(
            {plan_id: 10}, ocr_payload: "payload", manually_corrected_fields: ["INSURANCE"]
          )
          success_at = projection.reload.success_validation_at
          last_event_at = recognition.reload.events.last.created_at
          expect(success_at).to be_within(2.seconds).of(last_event_at)
          expect(projection.verification_required).to eq true
          expect(projection.verified_fields).to eq ["INSURANCE"]
        end

        it "does not have the verification_required field" do
          recognition.started_recognition!(task_id)
          projection = OCR::BIProjection.find_by(recognition: recognition)

          recognition.validated_product_successfully!({plan_id: 10}, ocr_payload: "payload")
          projection.reload
          expect(projection.verification_required).to eq false
          expect(projection.verified_fields).to eq []
        end
      end
    end

    context "when there is a product creation" do
      let(:product) { create(:product) }

      it "creates the product related fields" do
        recognition.started_recognition!(task_id)
        projection = OCR::BIProjection.find_by(recognition: recognition)

        recognition.created_product_successfully!(product)
        product_created_at_at = projection.reload.product_created_at
        last_event_at = recognition.reload.events.last.created_at
        expect(product_created_at_at).to be_within(2.seconds).of(last_event_at)
        expect(projection.category_name).to eq(product.category.name)
        expect(projection.subcompany_name).to eq(product.subcompany.name)
        expect(projection.recognizable).to eq(product)
        expect(projection.company_name).to eq(product.company.name)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::RecognitionDecorator, :integration, type: :decorator do
  describe "#external_id" do
    let(:task_id) { "task123456" }

    context "when there is not an event yet" do
      subject { create(:ocr_recognition).decorate }

      it "returns nil" do
        expect(subject.external_id).to be_nil
      end
    end

    context "when there is already a task" do
      subject { create(:ocr_recognition, :with_task_event, task_id: task_id).decorate }

      it "shows the correct task_id" do
        expect(subject.external_id).to eq task_id
      end
    end
  end

  describe "#category_name" do
    let(:plan) { create(:plan) }

    context "when there is not a successful product validation" do
      let(:ocr_recognition) { create(:ocr_recognition).decorate }

      it "returns the correct category_name" do
        expect(ocr_recognition.category_name).to be_nil

        ocr_recognition.validated_product_successfully!({plan_id: plan.id}, ocr_payload: "payload")

        expect(ocr_recognition.category_name).to eq plan.category.name
      end
    end
  end

  describe "#document_uploaded_at" do
    let(:time) { Time.current - 7.days }
    let(:task_id) { "task123456" }
    let(:ocr_recognition) { create(:ocr_recognition).decorate }

    it "returns the correct document upload" do
      expect(ocr_recognition.document_uploaded_at).to be_nil

      Timecop.freeze(time) do
        ocr_recognition.started_recognition!(task_id)
      end

      expect(ocr_recognition.document_uploaded_at).to eq time
    end
  end

  describe "#external_link" do
    let(:service_double) { instance_double(OCR::Service) }
    let(:task_id) { "task123456" }
    let(:ocr_recognition) { create(:ocr_recognition).decorate }
    let(:link) { "link" }

    before do
      allow(service_double).to receive(:task_link).and_return link
    end

    it "returns the correct insiders link" do
      expect(ocr_recognition.external_link(ocr_service: service_double)).to be_nil

      ocr_recognition.update!(external_id: task_id)

      expect(ocr_recognition.external_link(ocr_service: service_double)).to eq link
    end
  end

  describe "#successful_validation?" do
    let(:task_id) { "task_id" }
    let(:ocr_recognition) { create(:ocr_recognition).decorate }

    it "returns the correct result" do
      expect(ocr_recognition.successful_validation?).to eq false

      ocr_recognition.validated_product_with_errors!(["Plan must be present"], ocr_payload: "payload")
      expect(ocr_recognition.successful_validation?).to eq false

      ocr_recognition.validated_product_successfully!({plan_id: 10}, ocr_payload: "payload")
      expect(ocr_recognition.successful_validation?).to eq true

      ocr_recognition.validated_product_with_errors!(["Plan must be present"], ocr_payload: "payload")
      expect(ocr_recognition.successful_validation?).to eq false
    end
  end

  describe "#mandate" do
    let(:mandate) { create(:mandate) }
    let(:ocr_recognition) { create(:ocr_recognition).decorate }

    it "returns the correct mandate" do
      expect(ocr_recognition.mandate).to be_nil

      ocr_recognition.validated_product_successfully!({mandate_id: mandate.id}, ocr_payload: "payload")

      expect(ocr_recognition.mandate).to eq mandate
    end
  end

  describe "#validation_errors" do
    let(:ocr_recognition) { create(:ocr_recognition).decorate }
    let(:errors) { ["Plan must be present"] }
    let(:product_attributes) { {mandate_id: 10} }

    context "when there is only error event" do
      it "returns the correct mandate" do
        expect(ocr_recognition.validation_errors).to eq []

        ocr_recognition.validated_product_with_errors!(errors, ocr_payload: "payload")
        expect(ocr_recognition.validation_errors).to eq errors
      end
    end

    context "when there is a success event after a failed one" do
      it "returns the correct mandate" do
        ocr_recognition.validated_product_with_errors!(errors, ocr_payload: "payload")
        ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")

        expect(ocr_recognition.validation_errors).to eq []
      end
    end

    context "when there is a failed event after a successful one" do
      it "returns the correct mandate" do
        ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
        ocr_recognition.validated_product_with_errors!(errors, ocr_payload: "payload")

        expect(ocr_recognition.validation_errors).to eq errors
      end
    end
  end

  describe "#validation_at" do
    let(:failed_validation_time) { Time.current - 7.days }
    let(:successful_validation_time) { Time.current - 3.days }
    let(:ocr_recognition) { create(:ocr_recognition).decorate }

    it "returns the correct document upload" do
      expect(ocr_recognition.validation_at).to be_nil

      Timecop.freeze(failed_validation_time) do
        ocr_recognition.validated_product_with_errors!(["Errors"], ocr_payload: "payload")
      end
      expect(ocr_recognition.validation_at).to eq failed_validation_time

      Timecop.freeze(successful_validation_time) do
        ocr_recognition.validated_product_successfully!({mandate_id: 10}, ocr_payload: "payload")
      end
      expect(ocr_recognition.validation_at).to eq successful_validation_time
    end
  end
end

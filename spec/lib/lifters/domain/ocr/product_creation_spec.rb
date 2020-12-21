# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OCR::ProductCreation, :integration do
  describe "#call" do
    subject { described_class.new(product_attributes, ocr_recognition) }

    let(:plan) { create(:plan) }
    let!(:ocr_recognition) { create(:ocr_recognition, document: create(:document)) }

    context "with a valid product" do
      let(:product_attributes) { attributes_for(:product, plan_id: plan.id) }

      it "creates the product and the event" do
        expect(DeleteOCRTaskJob).to receive(:perform_later).with(ocr_recognition.id)
        expect { subject.call }.to change(Product, :count).by(1)
        product = Product.last
        expect(product.number).to eq product_attributes[:number]
        event = ocr_recognition.find_event(OCR::Event::PRODUCT_CREATION_SUCCEDED)
        expect(event.payload["product_id"]).to eq product.id

        expect(product.documents.count).to eq 1
        document_product = product.documents.first
        expect(document_product.documentable).to eq product
        expect(document_product).not_to eq ocr_recognition.document
      end
    end

    context "when the recognition has a successful validation" do
      let(:product_attributes) { attributes_for(:product, plan_id: plan.id) }

      it "does not delete the task" do
        ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
        expect(DeleteOCRTaskJob).not_to receive(:perform_later).with(ocr_recognition.id)
        subject.call
      end
    end

    context "with a valid_product and a inquiry via param" do
      let(:inquiry) { create(:inquiry, state: :contacted) }
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry, category: plan.category) }
      let(:product_attributes) { attributes_for(:product, plan_id: plan.id, inquiry_id: inquiry.id) }

      it "creates the product and closes the inquiry" do
        expect { subject.call }.to change(Product, :count).by(1)
        expect(inquiry.reload.state).to eq "completed"
      end
    end

    context "when infering inquiry" do
      let(:mandate) { create(:mandate) }
      let(:inquiry) { create(:inquiry, state: :contacted, mandate: mandate) }
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry, category: plan.category) }

      let(:product_attributes) { attributes_for(:product, mandate_id: mandate.id, plan_id: plan.id) }

      it "closes the inquiries" do
        product = subject.call

        expect(Product.count).to be(1)
        expect(inquiry.reload.state).to eq "completed"
        expect(product.inquiry).to eq(inquiry)
      end
    end

    context "with inquiry but without mandate" do
      let(:mandate) { create(:mandate) }
      let(:inquiry) { create(:inquiry, state: :contacted, mandate: mandate) }
      let!(:inquiry_category) { create(:inquiry_category, inquiry: inquiry, category: plan.category) }

      let(:product_attributes) { attributes_for(:product, plan_id: plan.id) }

      it "closes the inquiries" do
        expect { subject.call }.to change(Product, :count).by(1)
        expect(inquiry.reload.state).to eq "contacted"
      end
    end

    context "when mandate has more than one open inquiry" do
      let(:mandate) { create(:mandate) }
      let(:product_attributes) { attributes_for(:product, plan_id: plan.id, mandate: mandate) }

      before do
        create_list(:inquiry, 2, state: :contacted, mandate: mandate)
      end

      it "does not set inquiry to product" do
        product = subject.call

        expect(product.inquiry).to be_nil
      end
    end

    context "with a invalid product" do
      let(:product_attributes) { attributes_for(:product, plan_id: plan.id, number: nil) }

      it "does not create the product nor the event" do
        expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)

        event = ocr_recognition.find_event(OCR::Event::PRODUCT_CREATION_SUCCEDED)
        expect(event).to be_nil
      end
    end
  end
end

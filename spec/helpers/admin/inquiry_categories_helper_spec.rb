# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::InquiryCategoriesHelper do
  subject { Object.new.extend(Admin::InquiryCategoriesHelper) }

  describe "#show_send_to_ocr?" do
    before do
      allow(Features).to receive(:active?).and_call_original
      allow(Features).to receive(:active?).with(Features::OCR).and_return(true)
    end

    let(:inquiry_category) do
      create(:inquiry_category, inquiry: inquiry, category: plan.category, documents: documents)
    end
    let(:inquiry) { create(:inquiry, subcompany: plan.subcompany) }
    let(:documents) { build_list(:document, 1, :shallow, :customer_upload) }
    let(:plan) { create(:plan, plan_state_begin: Date.new(2018, 1)) }

    context "with plans with plan state" do
      it "returns true" do
        expect(subject.show_send_to_ocr?(inquiry_category)).to be_truthy
      end
    end

    context "with plans but without plan state" do
      let(:plan) { create(:plan, :without_plan_state) }

      it "returns false" do
        expect(subject.show_send_to_ocr?(inquiry_category)).not_to be_truthy
      end
    end

    context "with 2 documents" do
      let(:documents) { build_list(:document, 2, :shallow, :customer_upload) }

      it "returns false" do
        expect(subject.show_send_to_ocr?(inquiry_category)).not_to be_truthy
      end
    end
  end
end

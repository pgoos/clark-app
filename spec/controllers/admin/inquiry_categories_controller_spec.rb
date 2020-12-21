# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::InquiryCategoriesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/inquiry_categories")) }
  let(:admin) { create(:admin, role: role) }
  let(:inquiry) { create(:inquiry) }
  let(:inquiry_category) { create(:inquiry_category, inquiry: inquiry) }

  before { sign_in(admin) }

  describe "POST send_no_product_can_be_created_email" do
    let(:lifter_double) { instance_double(Domain::Inquiries::NoProductCanBeCreated) }
    let(:params) do
      {
        locale: :de,
        inquiry_id: inquiry.id,
        id: inquiry_category.id,
        possible_reasons: %w[payable_contribution payment_method],
        additional_information: "Test",
      }
    end

    before do
      allow(Domain::Inquiries::NoProductCanBeCreated).to \
        receive(:new).with(inquiry_category.id, admin).and_return(lifter_double)
      allow(lifter_double).to receive(:call)
    end

    context "with successful actions" do
      before do
        post :send_no_product_can_be_created_email, params: params, format: :js
      end

      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:send_no_product_can_be_created_email) }
    end

    context "when calling the lifter" do
      let(:expected_arguments) do
        ActionController::Parameters.new(params.slice(:possible_reasons, :additional_information)).permit!
      end

      it "calls NoProductCanBeCreated lifter" do
        expect(lifter_double).to receive(:call).with(expected_arguments)

        post :send_no_product_can_be_created_email, params: params, format: :js
      end
    end

    context "when calling the original lifter" do
      before do
        allow(Domain::Inquiries::NoProductCanBeCreated).to receive(:new).and_call_original
      end

      it "creates an interaction" do
        expect {
          post :send_no_product_can_be_created_email, params: params, format: :js
        }.to change(Interaction::Email, :count).by(1)
      end
    end
  end

  describe "POST send_to_ocr" do
    let(:lifter_double) { instance_double(Domain::Inquiries::SendToOCR) }
    let(:params) do
      {
        locale: :de,
        inquiry_id: inquiry.id,
        id: inquiry_category.id
      }
    end

    before do
      allow(Domain::Inquiries::SendToOCR).to \
        receive(:new).with(inquiry_category).and_return(lifter_double)
      allow(lifter_double).to receive(:send_to_ocr)
    end

    context "with successful actions" do
      before do
        post :send_to_ocr, params: params, format: :js
      end

      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:send_to_ocr) }
    end

    context "when calling the lifter" do
      it "should call NoProductCanBeCreated lifter" do
        expect(lifter_double).to receive(:send_to_ocr).with(no_args)

        post :send_to_ocr, params: params, format: :js
      end
    end
  end
end

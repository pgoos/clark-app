# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Ocr::ProductsController, :integration do
  let!(:ocr_recognition) { create(:ocr_recognition) }

  let(:roles) { create(:role, permissions: Permission.where(controller: "admin/ocr/products")) }
  let(:admin) { create(:admin, role: roles) }

  before { login_admin(admin) }

  describe "GET /new" do
    let(:product_attributes) { {mandate_id: 10} }

    before do
      ocr_recognition.validated_product_successfully!(product_attributes, ocr_payload: "payload")
    end

    it "creates the correct product" do
      get :new, params: {locale: I18n.locale, ocr_recognition_id: ocr_recognition.id}
      expect(response).to have_http_status(:success)
      expect(assigns(:product).attributes).to eq(Product.new(product_attributes).attributes)
    end
  end

  describe "POST /" do
    let(:plan) { create(:plan) }
    let(:inquiry) { create(:inquiry) }
    let!(:product_params) { attributes_for(:product, inquiry_id: inquiry.id, plan_id: plan.id) }
    let!(:ocr_recognition) { create(:ocr_recognition, document: create(:document)) }

    context "when product is created with a mandate_id" do
      let(:overrided_product_params) { product_params.merge(inquiry_id: nil, mandate_id: inquiry.mandate.id) }

      it "creates a new product" do
        params = {product: overrided_product_params, ocr_recognition_id: ocr_recognition.id, locale: I18n.locale}
        post(:create, params: params)

        expect(response).to redirect_to(admin_mandate_path(inquiry.mandate))
        expect(subject).to set_flash[:notice]
        expect(Product.count).to eq 1
        expect(Product.last.inquiry).to eq nil
        expect(Product.last.mandate).to eq inquiry.mandate
      end
    end

    context "when product is created with a mandate_id and it has an open inquiry" do
      let(:plan) { create(:plan) }
      let(:inquiry) { create(:inquiry, :contacted) }
      let(:overrided_product_params) { product_params.merge(inquiry_id: nil, mandate_id: inquiry.mandate.id) }

      before do
        create(:inquiry_category, inquiry: inquiry, category: plan.category)
      end

      it "creates a new product" do
        params = { product: overrided_product_params, ocr_recognition_id: ocr_recognition.id, locale: I18n.locale }
        post(:create, params: params)

        expect(response).to redirect_to(admin_inquiry_path(inquiry))
        expect(subject).to set_flash[:notice]
        expect(Product.count).to eq 1
        expect(Product.last.inquiry).to eq inquiry
        expect(Product.last.mandate).to eq inquiry.mandate
      end
    end

    context "when product is valid" do
      it "creates a new product" do
        params = {product: product_params, ocr_recognition_id: ocr_recognition.id, locale: I18n.locale}
        post(:create, params: params)

        expect(response).to redirect_to(admin_inquiry_path(inquiry))
        expect(subject).to set_flash[:notice]
        expect(Product.count).to eq 1
        expect(Product.last.inquiry).to eq inquiry
        expect(Product.last.mandate).to eq inquiry.mandate
      end
    end

    context "when product is invalid" do
      let(:product_params) { attributes_for(:product, plan_id: plan.id, number: nil) }

      it "does not save product" do
        request.env["HTTP_REFERER"] = "/de/admin"

        params = {product: product_params, ocr_recognition_id: ocr_recognition.id, locale: I18n.locale}
        post(:create, params: params)

        expect(response).to have_http_status(:redirect)
        expect(Product.count).to eq 0
        expect(subject).to set_flash[:alert]
      end
    end
  end
end

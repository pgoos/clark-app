# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ContractsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/contracts")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "#move_to_success" do
    let(:contract) { create(:contract, :details_missing) }
    let(:params) do
      {
        locale: "de",
        format: :js,
        id: contract.id
      }
    end

    context "with successful actions" do
      before do
        params
        patch :move_to_success, params: params
      end

      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:move_to_success) }
    end
  end

  describe "#request_correction" do
    let(:contract) { create(:contract, :under_analysis, :with_customer_uploaded_document) }
    let(:product) { Product.find(contract.id) }
    let(:params) do
      {
        locale: "de",
        format: :js,
        id: contract.id,
        possible_reasons: ["contract_expiry_date"],
        additional_information: "please reupload document"
      }
    end

    context "with valid params" do
      it "succeeds" do
        post :request_correction, params: params
        expect(response.status).to eq 200
        expect(product.analysis_state).to eq "analysis_failed"
        expect(Interaction::Email.find_by(topic_id: product.id, topic_type: Product.name)).not_to be_nil
      end
    end
  end

  describe "#update_analysis_state" do
    context "when there is a contract" do
      let(:analysis_state_event) { :information_missing }
      let(:contract) { create(:contract, :under_analysis) }
      let(:product) { Product.find(contract.id) }

      it "retrieves contract and updates its analysis_state" do
        params = { locale: I18n.locale, id: contract.id, analysis_state_event: analysis_state_event }
        patch :update_analysis_state, params: params

        expect(response.status).to eq 302
        expect(response).to redirect_to admin_product_path(contract.id)
        expect(flash[:notice]).to eq "Analysis state successfully changed"
        expect(product.analysis_state).to eq "analysis_failed"
      end
    end

    context "when there isn't a contract" do
      let(:analysis_state_event) { :information_missing }

      it "returns an error" do
        params = { locale: I18n.locale, id: 10, analysis_state_event: analysis_state_event }
        patch :update_analysis_state, params: params

        expect(response.status).to eq 302
        expect(response).to redirect_to admin_products_path
        expect(flash[:notice]).to eq "Contract not found"
      end
    end
  end
end

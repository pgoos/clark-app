# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Home24Controller, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/home24")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "GET show" do
    let!(:home24_mandate) { create(:mandate, :home24, state: :accepted) }
    let!(:initiated_export_mandate) { create(:mandate, :home24, state: :accepted, export_state: "initiated") }
    let!(:completed_export_mandate) { create(:mandate, :home24, state: :accepted, export_state: "completed") }
    let!(:first_product) {
      create(:product, mandate: home24_mandate, state: Home24::Entities::Product::ACTIVE_STATES[0])
    }
    let!(:second_product) {
      create(:product, mandate: home24_mandate, state: Home24::Entities::Product::ACTIVE_STATES[1])
    }

    it "responds with success and assigns mandates ready to export" do
      get :show, params: { locale: I18n.locale }

      expect(response).to have_http_status(:ok)
      expect(assigns(:mandates).map(&:id)).to eq([home24_mandate.id])
    end

    context "when there are filtered mandates initiated to export" do
      it "responds with success and assigns mandates initiated to export" do
        get :show, params: { locale: I18n.locale, export_state: "initiated" }

        expect(response).to have_http_status(:ok)
        expect(assigns(:mandates).map(&:id)).to eq([initiated_export_mandate.id])
      end
    end

    context "when there are filtered mandates that has completed export" do
      it "responds with success and assigns mandates completed export" do
        get :show, params: { locale: I18n.locale, export_state: "completed" }

        expect(response).to have_http_status(:ok)
        expect(assigns(:mandates).map(&:id)).to eq([completed_export_mandate.id])
      end
    end
  end

  describe "POST export_customers" do
    let(:params) { { locale: I18n.locale } }

    it "initiates customers export through InitiateCustomersExportJob" do
      expect(Home24::Jobs::InitiateCustomersExportJob)
        .to receive(:perform_later)
        .with(max_no_of_customers: nil)

      post :export_customers, params: params

      expect(response).to have_http_status(:redirect)
    end

    context "when there is passed one forced customer_id" do
      let(:params) { { locale: I18n.locale, forced_customer_ids: ["99"] } }

      it "initiates customers export directly to home24 public interface" do
        expect(Home24)
          .to receive(:initiate_customers_export)
          .with(forced_customer_ids: params[:forced_customer_ids])

        post :export_customers, params: params

        expect(response).to have_http_status(:redirect)
      end
    end

    context "when there are passed more than one customer id" do
      let(:params) { { locale: I18n.locale, forced_customer_ids: %w[99 100] } }

      it "initiates customers export through InitiateCustomersExportJob passing forced_customer_ids" do
        expect(Home24::Jobs::InitiateCustomersExportJob)
          .to receive(:perform_later)
          .with(forced_customer_ids: params[:forced_customer_ids])

        post :export_customers, params: params

        expect(response).to have_http_status(:redirect)
      end
    end

    context "when there is passed max_no_of_customers" do
      let(:params) { { max_no_of_customers: "1", locale: I18n.locale } }

      it "initiates customers export through InitiateCustomersExportJob passing forced_customer_ids" do
        expect(Home24::Jobs::InitiateCustomersExportJob)
          .to receive(:perform_later)
          .with(max_no_of_customers: params[:max_no_of_customers])

        post :export_customers, params: params

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end

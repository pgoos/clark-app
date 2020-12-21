# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::VoucherMandatesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/voucher_mandates")) }
  let(:admin) { create(:admin, role: role) }
  let!(:voucher) { create(:voucher) }
  let(:default_accepted_interval) { Report::Marketing::VoucherCustomerRepository::DEFAULT_ACCEPTED_INTERVAL }

  before { login_admin(admin) }

  describe "GET index" do
    it "responds with success" do
      get :index, params: { locale: I18n.locale }

      expect(response).to have_http_status(:ok)
    end

    context "when request format is csv" do
      before { get :index, params: { locale: I18n.locale }, format: :csv }

      let(:filename) { "VoucherCustomer_L7D_#{DateTime.current.strftime('%Y_%m_%d')}.csv" }

      it "responds with correct csv" do
        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include "text/csv"
        expect(response.header["Content-Disposition"]).to include "attachment; filename=\"#{filename}\""
      end
    end

    context "when mandate is not accepted" do
      let!(:mandate) { create :mandate, :created, voucher: voucher }

      it "doesnt assigns mandate" do
        get :index, params: { locale: I18n.locale }

        expect(assigns(:mandates)).not_to include mandate
      end
    end

    context "when mandate doesn't have voucher" do
      let!(:mandate) { create :mandate, :accepted }

      before do
        create(
          :business_event,
          action: :accept,
          entity: mandate,
          created_at: Faker::Time.between(from: default_accepted_interval.ago, to: DateTime.now)
        )
      end

      it "does NOT assign mandate" do
        get :index, params: { locale: I18n.locale }

        expect(assigns(:mandates)).not_to include mandate
      end
    end

    context "when accepted mandate has voucher but doesn't match accepted_at range filtering" do
      let!(:mandate) { create :mandate, :accepted }

      before do
        create(
          :business_event,
          action: :accept,
          entity: mandate,
          created_at: default_accepted_interval.ago - 1.day
        )
      end

      it "does NOT assign mandate" do
        get :index, params: { locale: I18n.locale }

        expect(assigns(:mandates)).not_to include mandate
      end
    end

    context "when accepted mandate has voucher and matches accepted_at range filtering" do
      let!(:mandate) { create :mandate, :accepted, :with_user, voucher: voucher }

      before do
        create(
          :business_event,
          action: :accept,
          entity: mandate,
          created_at: Faker::Time.between(from: default_accepted_interval.ago, to: DateTime.now)
        )
      end

      it "assigns mandate" do
        get :index, params: { locale: I18n.locale }

        expect(assigns(:mandates)).to include mandate
      end
    end
  end
end

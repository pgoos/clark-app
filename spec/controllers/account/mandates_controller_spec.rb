# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account::MandatesController, :integration, type: :controller do
  describe "GET profiling" do
    context "as a user" do
      it "opens the profiling page" do
        sign_in create(:user, mandate: create(:mandate))
        get :profiling, params: {locale: I18n.locale}
        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "does not open the targeting page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead
        get :profiling, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end

    context "as not logged in" do
      it "does not open the profiling page" do
        get :profiling, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "GET targeting" do
    context "as a user" do
      it "opens the targeting page" do
        sign_in create(:user, mandate: create(:mandate))
        get :targeting, params: {locale: I18n.locale}
        expect(response).to have_http_status(:success)
      end
    end

    context "as a lead" do
      it "opens the targeting page" do
        device_lead = create(:device_lead, mandate: create(:mandate))
        sign_in device_lead, scope: :lead
        get :targeting, params: {locale: I18n.locale}
        expect(response).to have_http_status(:success)
      end
    end

    context "as not logged in" do
      it "does not open the targeting page" do
        get :targeting, params: {locale: I18n.locale}
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "PUT profiling" do
    let(:mandate) { create :mandate }

    before { sign_in create(:user, mandate: mandate) }

    it "updates profiling info" do
      get :profiling, params: {
        locale: I18n.locale,
        first_name: "New Name",
        address: {street: "New Street"}
      }
      expect(response).to have_http_status(:success)
    end
  end
end

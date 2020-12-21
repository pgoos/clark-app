# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdvertiserCostAttributionsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/advertiser_cost_attributions")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "GET index" do
    it "responds with success" do
      create :advertiser_cost_attribution
      get :index, params: { locale: :de }
      expect(response.status).to eq 200
    end

    %i[ad_provider campaign_name adgroup_name creative_name].each do |field|
      context "when by_#{field} param is passed" do
        before { get :index, params: { :locale => :de, "by_#{field}" => "ria" } }

        let!(:attribution_in_scope) { create(:advertiser_cost_attribution, field => "triangle") }
        let!(:attribution_out_scope) { create(:advertiser_cost_attribution, field => "rectangle") }

        it "shows matched records" do
          expect(response.status).to eq 200
          expect(assigns(:advertiser_cost_attributions)).to include(attribution_in_scope)
          expect(assigns(:advertiser_cost_attributions)).not_to include(attribution_out_scope)
        end
      end
    end

    context "when by_mkt_channel param is passed" do
      before { get :index, params: { :locale => :de, "by_mkt_channel" => "search" } }

      let!(:attribution_in_scope) { create(:advertiser_cost_attribution, ad_provider: "Moogle") }
      let!(:attribution_out_scope) { create(:advertiser_cost_attribution, ad_provider: "Daysbook") }
      let!(:mapping_in_scope) { create(:advertiser_channel_mapping, ad_provider: "Moogle", mkt_channel: "search") }
      let!(:mapping_out_scope) { create(:advertiser_channel_mapping, ad_provider: "Daysbook", mkt_channel: "organic") }

      it "shows matched records" do
        expect(response.status).to eq 200
        expect(assigns(:advertiser_cost_attributions)).to include(attribution_in_scope)
        expect(assigns(:advertiser_cost_attributions)).not_to include(attribution_out_scope)
      end
    end
  end

  describe "POST create" do
    before do
      params = { ad_provider: "FOO", cost_calculation_type: "incentive", cost_cents: 100 }
      post :create, params: { locale: :de, advertiser_cost_attribution: params }
    end

    it "creates a new record" do
      record = AdvertiserCostAttribution.last
      expect(record).to be_present
      expect(response).to redirect_to admin_advertiser_cost_attribution_path(id: record.id)
    end
  end

  describe "PATCH update" do
    let(:record) { create :advertiser_cost_attribution }

    before do
      params = { customer_platform: "android" }
      patch :update, params: { locale: :de, id: record.id, advertiser_cost_attribution: params }
    end

    it "updates a record" do
      expect(response).to redirect_to admin_advertiser_cost_attribution_path(id: record.id)
      expect(record.reload.customer_platform).to eq "android"
    end
  end
end

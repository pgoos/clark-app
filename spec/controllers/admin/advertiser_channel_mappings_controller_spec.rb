# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdvertiserChannelMappingsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/advertiser_channel_mappings")) }
  let(:admin) { create(:admin, role: role) }

  before { sign_in(admin) }

  describe "GET index" do
    it "responds with success" do
      create :advertiser_channel_mapping
      get :index, params: {locale: :de}
      expect(response.status).to eq 200
    end
  end

  describe "POST create" do
    before do
      ad_params = {ad_provider: "FOO", mkt_channel: :facebook}
      post :create, params: {locale: :de, advertiser_channel_mapping: ad_params}
    end

    it "creates a new record" do
      record = AdvertiserChannelMapping.last
      expect(record).to be_present
      expect(response).to redirect_to edit_admin_advertiser_channel_mapping_path(id: record.id)
    end
  end

  describe "PATCH update" do
    let(:record) { create :advertiser_channel_mapping }

    before do
      ad_params = {campaign_name: "FOO", adgroup_name: "BAR", creative_name: "BAZ"}
      patch :update, params: {locale: :de, id: record.id, advertiser_channel_mapping: ad_params}
    end

    it "updates a record" do
      expect(response).to redirect_to edit_admin_advertiser_channel_mapping_path(id: record.id)
      expect(record.reload.campaign_name).to eq "FOO"
      expect(record.adgroup_name).to eq "BAR"
      expect(record.creative_name).to eq "BAZ"
    end
  end
end

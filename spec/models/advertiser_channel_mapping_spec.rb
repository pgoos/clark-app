# frozen_string_literal: true
# == Schema Information
#
# Table name: advertiser_channel_mappings
#
#  id            :integer          not null, primary key
#  ad_provider   :string           not null
#  campaign_name :string
#  adgroup_name  :string
#  creative_name :string
#  mkt_channel   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#


require "rails_helper"

RSpec.describe AdvertiserChannelMapping, type: :model do
  it { is_expected.to validate_presence_of(:ad_provider) }
  it { is_expected.to validate_presence_of(:mkt_channel) }

  context "uniqueness of ad_provider" do
    context "when there is channel mappings with the same ad_provider" do
      before { create :advertiser_channel_mapping, :organic, ad_provider: "Test" }

      context "and with different mkt_channel" do
        it "adds an error" do
          channel_mapping = build :advertiser_channel_mapping, :email, ad_provider: "Test"
          channel_mapping.validate
          expect(channel_mapping.errors[:ad_provider]).not_to be_empty
        end
      end

      context "and with the same mkt_channel" do
        it "does not add any error" do
          channel_mapping = build :advertiser_channel_mapping, :organic, ad_provider: "Test"
          channel_mapping.validate
          expect(channel_mapping.errors[:ad_provider]).to be_empty
        end
      end
    end
  end
end

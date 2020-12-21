# frozen_string_literal: true

# == Schema Information
#
# Table name: advertiser_cost_attributions
#
#  id                    :integer          not null, primary key
#  start_report_interval :datetime
#  end_report_interval   :datetime
#  ad_provider           :string           not null
#  campaign_name         :string
#  adgroup_name          :string
#  creative_name         :string
#  cost_calculation_type :string           not null
#  customer_platform     :string
#  cost_cents            :integer          not null
#  cost_currency         :string           default("EUR")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  brand                 :boolean          not null
#

require "rails_helper"

RSpec.describe AdvertiserCostAttribution, type: :model do
  subject(:attribution) { FactoryBot.build :advertiser_cost_attribution }

  it do
    expect(subject)
      .to have_one(:advertiser_channel_mapping).with_primary_key("ad_provider").with_foreign_key("ad_provider")
  end

  it { is_expected.to validate_presence_of :ad_provider }
  it { is_expected.to validate_presence_of :cost_calculation_type }
  it { is_expected.to validate_presence_of :cost_cents }
  it { is_expected.to validate_numericality_of(:cost_cents).is_greater_than_or_equal_to(0) }

  it { is_expected.not_to validate_presence_of :customer_platform }
  it { is_expected.not_to validate_presence_of :start_report_interval }
  it { is_expected.not_to validate_presence_of :end_report_interval }
  it { is_expected.not_to validate_presence_of :campaign_name }
  it { is_expected.not_to validate_presence_of :adgroup_name }

  context "with cpi const calculation type" do
    subject { FactoryBot.build :advertiser_cost_attribution, :cpi }

    it { is_expected.to validate_presence_of(:customer_platform).with_message(:blank_when_cpi) }
  end

  context "with fixed const calculation type" do
    subject { FactoryBot.build :advertiser_cost_attribution, :fixed }

    it do
      expect(subject).to validate_presence_of(:start_report_interval).with_message(:blank_when_fixed)
    end

    it do
      expect(subject).to validate_presence_of(:end_report_interval).with_message(:blank_when_fixed)
    end
  end

  context "with adgroup name" do
    subject { FactoryBot.build :advertiser_cost_attribution, adgroup_name: "FOO" }

    it do
      expect(subject).to validate_presence_of(:campaign_name)
        .with_message(:blank_when_adgroup_present)
    end
  end

  context "with creative name" do
    subject { FactoryBot.build :advertiser_cost_attribution, creative_name: "FOO" }

    it do
      expect(subject).to validate_presence_of(:adgroup_name)
        .with_message(:blank_when_creative_present)
    end
  end

  context "validation of report interval" do
    subject(:attribution) do
      build(
        :advertiser_cost_attribution,
        start_report_interval: 2.days.ago,
        end_report_interval:   1.day.ago
      )
    end

    context "when end date before start" do
      it "adds an error" do
        attribution.end_report_interval = 3.days.ago
        attribution.validate
        expect(attribution.errors.details[:end_report_interval])
          .to include(error: :before_start_interval)
      end
    end

    context "when end date after start" do
      it "does not add an error" do
        attribution.validate
        expect(attribution.errors.details[:end_report_interval])
          .not_to include(error: :before_start_interval)
      end
    end

    context "when report interval is overlapped" do
      before do
        create(
          :advertiser_cost_attribution,
          start_report_interval: 3.days.ago,
          end_report_interval:   attribution.end_report_interval + 1.day
        )
      end

      it "adds an error" do
        attribution.validate
        expect(attribution.errors.details[:base]).to include(error: :cost_interval_overlapped)
      end
    end

    context "when report interval is not overlapped" do
      before do
        create(
          :advertiser_cost_attribution,
          start_report_interval: 1.hour.ago,
          end_report_interval:   1.minute.ago
        )
      end

      it "does not add an error" do
        attribution.validate
        expect(attribution.errors.details[:base]).not_to include(error: :cost_interval_overlapped)
      end
    end
  end

  context "when there is an existing entry with different brand value" do
    before do
      create(
        :advertiser_cost_attribution,
        start_report_interval: attribution.start_report_interval,
        end_report_interval:   attribution.end_report_interval,
        brand: true
      )
    end

    it "does not add an error" do
      attribution.validate
      expect(attribution.errors.details[:base]).not_to include(error: :cost_interval_overlapped)
    end
  end

  context "when there is campaign for ad provider" do
    before do
      create(
        :advertiser_cost_attribution,
        ad_provider:           attribution.ad_provider,
        cost_calculation_type: attribution.cost_calculation_type,
        campaign_name:         "FOO"
      )
    end

    it "validates presence of campaign name" do
      expect(subject).to validate_presence_of(:campaign_name)
        .with_message(:blank_when_there_exist_campaign_for_ad_provider)
    end
  end

  context "with blank campaign and the same ad provider and cost type" do
    before do
      create(
        :advertiser_cost_attribution,
        ad_provider:           attribution.ad_provider,
        cost_calculation_type: attribution.cost_calculation_type,
        adgroup_name:          "",
        creative_name:         "",
        campaign_name:         ""
      )
    end

    it "does not validate presence of campaign name" do
      expect(subject).not_to validate_presence_of(:campaign_name)
        .with_message(:blank_when_there_exist_campaign_for_ad_provider)
    end
  end

  context "when there is adgroup for campaign" do
    before do
      create(
        :advertiser_cost_attribution,
        ad_provider:           attribution.ad_provider,
        cost_calculation_type: attribution.cost_calculation_type,
        campaign_name:         attribution.campaign_name,
        adgroup_name:          "FOO"
      )
    end

    it "validates presence of adgroup name" do
      expect(subject).to validate_presence_of(:adgroup_name)
        .with_message(:blank_when_there_exist_adgroup_for_campaign)
    end
  end

  context "when there is creative for adgroup" do
    before do
      create(
        :advertiser_cost_attribution,
        ad_provider:           attribution.ad_provider,
        cost_calculation_type: attribution.cost_calculation_type,
        campaign_name:         attribution.campaign_name,
        adgroup_name:          attribution.adgroup_name,
        creative_name:         "FOO"
      )
    end

    it "validates presence of creative name" do
      expect(subject).to validate_presence_of(:creative_name)
        .with_message(:blank_when_creative_present)
    end
  end

  %i[ad_provider campaign_name adgroup_name creative_name].each do |field|
    describe "by_#{field} scope" do
      subject { described_class.send("by_#{field}", "ria") }

      let!(:attribution_in_scope) { create(:advertiser_cost_attribution, field => "triangle") }
      let!(:attribution_out_scope) { create(:advertiser_cost_attribution, field => "rectangle") }

      it "searches for matches in #{field}" do
        expect(subject).to include(attribution_in_scope)
        expect(subject).not_to include(attribution_out_scope)
      end
    end
  end

  describe "by_mkt_channel scope" do
    subject { described_class.by_mkt_channel("search") }

    let!(:attribution_in_scope) { create(:advertiser_cost_attribution, ad_provider: "Moogle") }
    let!(:attribution_out_scope) { create(:advertiser_cost_attribution, ad_provider: "Daysbook") }
    let!(:mapping_in_scope) { create(:advertiser_channel_mapping, ad_provider: "Moogle", mkt_channel: "search") }
    let!(:mapping_out_scope) { create(:advertiser_channel_mapping, ad_provider: "Daysbook", mkt_channel: "organic") }

    it "scopes on associated advertiser_channel_mapping's mkt_channel" do
      expect(subject).to include(attribution_in_scope)
      expect(subject).not_to include(attribution_out_scope)
    end
  end
end

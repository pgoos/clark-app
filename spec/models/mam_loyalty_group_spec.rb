# frozen_string_literal: true

# == Schema Information
#
# Table name: mam_loyalty_group
#
#  id                     :integer          not null, primary key
#  name                   :string
#  valid_from             :date
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_ident         :string
#  base_loyalty_group_id  :integer
#  default_fallback       :boolean

require "rails_helper"

RSpec.describe MamLoyaltyGroup, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  describe "by_date_with_campaign" do
    it "returns by valid from if no campaign was passed" do
      no_campaign = create(:mam_loyalty_group, campaign_ident: nil, valid_from: 1.month.ago.to_date)
      expect(described_class.by_date_with_campaign(1.day.ago.to_date, nil)).to eq([no_campaign])
    end

    it "returns by valid from and campaign ident" do
      campaign_ident = "campaign"
      no_campaign = create(:mam_loyalty_group, campaign_ident: nil, valid_from: 1.month.ago.to_date)
      with_campaign = create(:mam_loyalty_group, campaign_ident: campaign_ident, valid_from: 1.month.ago.to_date)
      expect(described_class.by_date_with_campaign(1.day.ago.to_date, campaign_ident)).to eq([with_campaign])
    end

    it "orders the results descending by valid from" do
      campaign_ident = "campaign"
      with_campaign_1_month = create(:mam_loyalty_group,
                                     campaign_ident: campaign_ident, valid_from: 1.month.ago.to_date)
      with_campaign_1_week = create(:mam_loyalty_group, campaign_ident: campaign_ident, valid_from: 1.week.ago.to_date)
      expect(described_class.by_date_with_campaign(1.day.ago.to_date, campaign_ident))
        .to eq([with_campaign_1_week, with_campaign_1_month])
    end
  end
  # Associations
  # Nested Attributes
  # Validations

  it { is_expected.to validate_uniqueness_of(:valid_from).scoped_to(:campaign_ident) }
  # Callbacks
  # Instance Methods
  # Class Methods
  describe ".default_loyalty_group_for" do
    let(:mandate) { create(:mandate, :with_accepted_tos, :mam) }

    it "returns nil if no loyalty groups defined in the db" do
      expect(described_class.default_loyalty_group_for(mandate)).to be_nil
    end

    it "returns the default loyalty group if valid from is less than the mandate creation date" do
      mandate.tos_accepted_at = 1.week.ago
      default_loyalty_group = create(:mam_loyalty_group, default_fallback: true, valid_from: 1.week.ago.to_date)
      expect(described_class.default_loyalty_group_for(mandate)).to eq(default_loyalty_group)
    end

    it "returns nil if no loyalty group with valid from is less than the mandate creation date" do
      mandate.tos_accepted_at = 1.week.ago
      create(:mam_loyalty_group, default_fallback: true, valid_from: 1.day.ago.to_date)
      expect(described_class.default_loyalty_group_for(mandate)).to be_nil
    end

    it "returns the most recent default group based on valid_from if multiple were found" do
      mandate.tos_accepted_at = 1.week.ago
      default_loyalty_group_week = create(:mam_loyalty_group, default_fallback: true, valid_from: 1.week.ago.to_date)
      default_loyalty_group_month = create(:mam_loyalty_group, default_fallback: true, valid_from: 1.month.ago.to_date)
      expect(described_class.default_loyalty_group_for(mandate)).to eq(default_loyalty_group_week)
    end
  end

  describe ".select_group_for" do
    let(:mandate) { create(:mandate, :with_accepted_tos, :mam) }
    let(:campaign_ident) { "campaign" }

    before do
      allow(mandate).to receive(:source_campaign).and_return(campaign_ident)
    end

    it "returns nil if no loyalty groups defined in the db" do
      expect(described_class.select_group_for(mandate)).to be_nil
    end

    it "returns the loyalty group if valid from is less than the mandate creation date with matching campaign ident" do
      mandate.tos_accepted_at = 1.week.ago
      loyalty_group = create(:mam_loyalty_group, valid_from: 1.week.ago.to_date, campaign_ident: campaign_ident)
      expect(described_class.select_group_for(mandate)).to eq(loyalty_group)
    end

    it "returns nil if no loyalty group matches and no default group is defined" do
      mandate.tos_accepted_at = 1.week.ago
      create(:mam_loyalty_group, default_fallback: false, valid_from: 1.day.ago.to_date)
      expect(described_class.select_group_for(mandate)).to be_nil
    end

    it "returns the most recent group based on valid_from if multiple were found" do
      mandate.tos_accepted_at = 1.week.ago
      loyalty_group_week = create(:mam_loyalty_group, valid_from: 1.week.ago.to_date, campaign_ident: campaign_ident)
      loyalty_group_month = create(:mam_loyalty_group, valid_from: 1.month.ago.to_date, campaign_ident: campaign_ident)
      expect(described_class.select_group_for(mandate)).to eq(loyalty_group_week)
    end

    it "falls back to a default group if no loyalty group matches" do
      mandate.tos_accepted_at = 1.week.ago
      loyalty_group_week = create(:mam_loyalty_group, valid_from: 1.week.ago.to_date, campaign_ident: "campaignnn")
      default_loyalty_group = create(:mam_loyalty_group, valid_from: 1.week.ago.to_date, default_fallback: true)
      expect(described_class.select_group_for(mandate)).to eq(default_loyalty_group)
    end
  end
end

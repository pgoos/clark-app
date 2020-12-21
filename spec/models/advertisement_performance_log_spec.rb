# frozen_string_literal: true
# == Schema Information
#
# Table name: advertisement_performance_logs
#
#  id                    :integer          not null, primary key
#  start_report_interval :datetime         not null
#  end_report_interval   :datetime         not null
#  ad_provider           :string           not null
#  campaign_name         :string           not null
#  adgroup_name          :string           not null
#  creative_name         :string
#  cost_cents            :integer          default(0), not null
#  cost_currency         :string           default("EUR"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  historical_values     :jsonb
#  provider_data         :jsonb
#  brand                 :boolean          not null
#


require "rails_helper"

RSpec.describe AdvertisementPerformanceLog, type: :model do

  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:start_report_interval) }
  it { is_expected.to validate_presence_of(:end_report_interval) }
  it { is_expected.to validate_presence_of(:ad_provider) }
  it { is_expected.to validate_presence_of(:campaign_name) }
  it { is_expected.to validate_presence_of(:adgroup_name) }
  it { is_expected.to validate_presence_of(:cost_cents) }
  it { is_expected.to validate_presence_of(:cost_currency) }

  # Callbacks
  # Instance Methods
  # Class Methods
end

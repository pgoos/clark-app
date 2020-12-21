# frozen_string_literal: true

# == Schema Information
#
# Table name: privacy_settings
#
#  id                   :bigint           not null, primary key
#  mandate_id           :integer          not null
#  third_party_tracking :jsonb
#
require "rails_helper"

RSpec.describe PrivacySetting, :slow, type: :model do
  # Setup

  subject { build(:privacy_setting) }

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # Index
  # State Machine
  # Scopes
  # Associations

  it { is_expected.to belong_to(:mandate) }

  # Nested Attributes
  # Validations

  context "when mandate is missing" do
    subject { build(:privacy_setting, mandate: nil) }

    it { is_expected.to be_invalid }
  end

  context "when third_party_tracking is missing" do
    subject { build(:privacy_setting, third_party_tracking: nil) }

    it { is_expected.to be_invalid }
  end

  context "when third_party_tracking has wrong keys" do
    subject do
      build(
        :privacy_setting,
        third_party_tracking: { enabled: false, some_weird_key: "YAY!" }
      )
    end

    it { is_expected.to be_invalid }
  end

  # Callbacks
  # Delegates
  # Instance Methods
  # Class Methods
  # Protected
  # Private
end

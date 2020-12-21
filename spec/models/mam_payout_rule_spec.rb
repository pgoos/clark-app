# frozen_string_literal: true

# == Schema Information
#
# Table name: mam_payout_rules
#
#  id                     :integer          not null, primary key
#  products_count         :integer          not null
#  base                   :integer          not null
#  ftl                    :integer          not null
#  sen                    :integer          not null
#  mam_loyalty_group_id   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null

require "rails_helper"

RSpec.describe MamPayoutRule, type: :model do
  subject { build(:mam_payout_rule) }
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

  it { is_expected.to validate_presence_of(:products_count) }
  it { is_expected.to validate_presence_of(:base) }
  it { is_expected.to validate_presence_of(:ftl) }
  it { is_expected.to validate_presence_of(:sen) }
  it { is_expected.to validate_presence_of(:mam_loyalty_group) }
  it { is_expected.to validate_uniqueness_of(:products_count).scoped_to(:mam_loyalty_group_id) }
  # Callbacks
  # Instance Methods
  # Class Methods
end


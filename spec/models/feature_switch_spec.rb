# == Schema Information
#
# Table name: feature_switches
#
#  id         :integer          not null, primary key
#  key        :string
#  active     :boolean
#  limit      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "rails_helper"

RSpec.describe FeatureSwitch, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins

  # Concerns
  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  # Associations
  # Nested Attributes

  # Validations
  it { is_expected.to validate_uniqueness_of(:key) }

  # Callbacks
  # Instance Methods
  # Class Methods
end


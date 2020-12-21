# frozen_string_literal: true
# == Schema Information
#
# Table name: cost_centers
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


require "rails_helper"

RSpec.describe Accounting::CostCenter, type: :model do
  subject { FactoryBot.build(:cost_center) }

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
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }

  # Callbacks
  # Instance Methods
  # Class Methods
end


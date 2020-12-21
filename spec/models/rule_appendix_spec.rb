# == Schema Information
#
# Table name: rule_appendices
#
#  id                :integer          not null, primary key
#  ident             :string
#  opportunity_value :integer
#  description       :text
#  audience          :text
#  content           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'rails_helper'

RSpec.describe RuleAppendix, type: :model do
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
  it { is_expected.to validate_uniqueness_of(:ident) }

  it { is_expected.to validate_presence_of(:ident) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:audience) }

  # Callbacks
  # Instance Methods

  # Class Methods
end

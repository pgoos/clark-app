# == Schema Information
#
# Table name: retirement_pensions
#
#  id                    :integer          not null, primary key
#  retirement_date_start :date             not null
#  retirement_date_end   :date
#  pension_value_east    :decimal(5, 2)    not null
#  pension_value_west    :decimal(5, 2)    not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'rails_helper'

RSpec.describe Retirement::Pension, type: :model do
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
  # Callbacks
  # Instance Methods
  pending "add some examples to (or delete) #{__FILE__}"

  # Class Methods

end


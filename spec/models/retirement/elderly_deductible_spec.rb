# == Schema Information
#
# Table name: retirement_elderly_deductibles
#
#  id                                   :integer          not null, primary key
#  year_customer_turns_65               :integer
#  deductible_percentage                :integer
#  deductible_max_amount_cents_cents    :integer          default(0), not null
#  deductible_max_amount_cents_currency :string           default("EUR"), not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#

require 'rails_helper'

RSpec.describe Retirement::ElderlyDeductible, type: :model do
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


# == Schema Information
#
# Table name: retirement_taxable_share_type_twos
#
#  id                          :integer          not null, primary key
#  year                        :integer
#  taxable_share_percentage    :integer
#  deductible_share_percentage :integer
#  max_deductible_cents        :integer          default(0), not null
#  max_deductible_currency     :string           default("EUR"), not null
#  deductible_addon_cents      :integer          default(0), not null
#  deductible_addon_currency   :string           default("EUR"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

require 'rails_helper'

RSpec.describe Retirement::TaxableShareTypeTwo, type: :model do
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


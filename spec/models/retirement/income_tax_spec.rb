# == Schema Information
#
# Table name: retirement_income_taxes
#
#  id                           :integer          not null, primary key
#  income_cents                 :integer          default(0), not null
#  income_currency              :string           default("EUR"), not null
#  income_tax_percentage        :integer
#  income_tax_church_percentage :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#

require 'rails_helper'

RSpec.describe Retirement::IncomeTax, type: :model do
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


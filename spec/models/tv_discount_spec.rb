# == Schema Information
#
# Table name: tv_discounts
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  discount   :float            not null
#  start      :datetime         not null
#  end        :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe TvDiscount do

  # Setup
  # ---------------------------------------------------------------------------------------

  # Settings
  # ---------------------------------------------------------------------------------------

  # Constants
  # ---------------------------------------------------------------------------------------

  # Attribute Settings
  # ---------------------------------------------------------------------------------------

  # Plugins
  # ---------------------------------------------------------------------------------------

  # Concerns
  # ---------------------------------------------------------------------------------------

  # State Machine
  # ---------------------------------------------------------------------------------------

  # Scopes
  # ---------------------------------------------------------------------------------------

  # Associations
  # ---------------------------------------------------------------------------------------

  # Nested Attributes
  # ---------------------------------------------------------------------------------------

  # Validations
  # ---------------------------------------------------------------------------------------
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:discount) }
  it { should validate_presence_of(:start) }
  it { should validate_presence_of(:end) }

  it {should validate_numericality_of(:discount).is_greater_than_or_equal_to(0.000).is_less_than_or_equal_to(100.000)}

  # Callbacks
  # ---------------------------------------------------------------------------------------

  # Instance Methods
  # ---------------------------------------------------------------------------------------

  # Class Methods
  # ---------------------------------------------------------------------------------------
end

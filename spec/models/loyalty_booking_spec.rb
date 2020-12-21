# == Schema Information
#
# Table name: loyalty_bookings
#
#  id            :integer          not null, primary key
#  mandate_id    :integer
#  bookable_id   :integer
#  bookable_type :string
#  kind          :integer
#  amount        :integer
#  details       :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

RSpec.describe LoyaltyBooking, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  it { expect(subject).to belong_to(:bookable) }
  it { expect(subject).to belong_to(:mandate) }
  # Nested Attributes
  # Validations
  it { is_expected.to validate_presence_of(:mandate) }
  # Callbacks
  # Instance Methods
  # Class Methods

end


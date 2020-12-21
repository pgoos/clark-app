# frozen_string_literal: true

# == Schema Information
#
# Table name: commission_rates
#
#  id            :integer          not null, primary key
#  subcompany_id :integer
#  category_id   :integer
#  pool          :string           not null
#  rate          :decimal(4, 2)    not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "rails_helper"

RSpec.describe CommissionRate, type: :model do
  it { is_expected.to belong_to :subcompany }
  it { is_expected.to belong_to :category }

  it { is_expected.to validate_presence_of :subcompany_id }
  it { is_expected.to validate_presence_of :category_id }
  it { is_expected.to validate_presence_of :pool }
  it { is_expected.to validate_presence_of :rate }
end

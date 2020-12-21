# frozen_string_literal: true

# == Schema Information
#
# Table name: retirement_cockpits
#
#  id                                          :integer          not null, primary key
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  mandate_id                                  :integer
#  desired_income_cents                        :integer
#  desired_income_currency                     :string           default("EUR")
#

require "rails_helper"

RSpec.describe Retirement::Cockpit, type: :model do
  it { is_expected.to belong_to(:mandate) }
  it { is_expected.to have_many(:appointments) }
end

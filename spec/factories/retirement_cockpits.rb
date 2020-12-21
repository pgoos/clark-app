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

FactoryBot.define do
  factory :retirement_cockpit, class: "Retirement::Cockpit" do
  end
end

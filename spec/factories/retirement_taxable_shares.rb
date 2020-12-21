# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_taxable_shares
#
#  id                             :integer          not null, primary key
#  year                           :integer
#  taxable_share_state_percentage :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#


FactoryBot.define do
  factory :retirement_taxable_share, class: "Retirement::TaxableShare" do
  end
end

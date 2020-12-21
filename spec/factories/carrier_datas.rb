# frozen_string_literal: true

# == Schema Information
#
# Table name: carrier_data
#
#  id                           :integer          not null, primary key
#  customer_number              :string
#  state                        :string
#  mandate_id                   :integer

FactoryBot.define do
  factory :carrier_data do
    customer_number { "1" }
    state { "" }
    mandate { build(:mandate) }
  end
end

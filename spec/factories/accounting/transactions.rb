# frozen_string_literal: true

# == Schema Information
#
# Table name: accounting_transactions
#
#  id               :integer          not null, primary key
#  transaction_type :string
#  settlement_date  :date
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string           default("EUR"), not null
#  reference_number :string
#  cost_center_id   :integer
#  entity_type      :string
#  entity_id        :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require "value_types"

FactoryBot.define do
  factory :accounting_transaction, class: "Accounting::Transaction" do
    transaction_type { ValueTypes::AccountingTransactionType::INITIAL_COMMISSION }
    settlement_date { "2017-09-27" }
    amount { 100 }
    reference_number { "MyString" }
    association :cost_center
  end
end

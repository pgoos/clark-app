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


require "rails_helper"

RSpec.describe Accounting::Transaction, type: :model do
  subject { FactoryBot.build(:accounting_transaction) }

  # Setup
  # Settings
  # Constants
  # Attribute Settings

  it "stores the transaction type as typed enum" do
    subject.transaction_type = ValueTypes::AccountingTransactionType::INITIAL_COMMISSION
    expect(subject).to be_initial_commission
  end

  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:transaction_type) }
  it { is_expected.to validate_presence_of(:settlement_date) }
  it { is_expected.to validate_presence_of(:amount_cents) }
  it { is_expected.to validate_presence_of(:amount_currency) }
  it { is_expected.to validate_presence_of(:cost_center_id) }

  # Callbacks
  # Instance Methods
  # Class Methods

end


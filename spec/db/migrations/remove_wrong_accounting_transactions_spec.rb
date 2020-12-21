# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "remove_wrong_accounting_transactions"

RSpec.describe RemoveWrongAccountingTransactions, :integration do
  describe "#data" do
    def transaction_exists?(id)
      Accounting::Transaction.exists?(id)
    end

    it "destroys only transactions with ProductDecorator type" do
      transaction1 = create(:accounting_transaction, entity_type: "ProductDecorator")
      transaction2 = create(:accounting_transaction, entity_type: "Product")

      described_class.new.data
      expect(transaction_exists?(transaction1.id)).to be_falsey
      expect(transaction_exists?(transaction2.id)).to be_truthy
    end

    it "ignores the transactions that do not have a ProductDecorator type" do
      transaction1 = create(:accounting_transaction, entity_type: "NewEntity")
      transaction2 = create(:accounting_transaction, entity_type: "Product")

      described_class.new.data
      expect(transaction_exists?(transaction1.id)).to be_truthy
      expect(transaction_exists?(transaction2.id)).to be_truthy
    end
  end
end

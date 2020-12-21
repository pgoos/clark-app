# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AccountingTransactionsController, :integration, type: :controller do
  let(:admin)   { create(:super_admin) }
  let(:mandate) { create :mandate, :accepted, products: [create(:product)] }

  let(:cost_center) { create(:cost_center) }
  let(:product) { create(:product) }

  let(:reference_number) { "transaction1" }
  let(:settlement_date) { Time.zone.today }
  let(:transaction_amount) { 100.01 }

  let(:initial_comission_type) do
    {
      value: ValueTypes::AccountingTransactionType::INITIAL_COMMISSION.name,
      type: "AccountingTransactionType"
    }
  end

  let(:reneval_comission_type) do
    {
      value: ValueTypes::AccountingTransactionType::RENEWAL_COMMISSION.name,
      type: "AccountingTransactionType"
    }
  end

  let(:existing_transaction) do
    create(
      :accounting_transaction,
      reference_number: "transaction2",
      settlement_date: settlement_date,
      entity_id: product.id,
      entity_type: "Product",
      cost_center: cost_center,
      amount: 202.02,
      transaction_type: ValueTypes::AccountingTransactionType::INITIAL_COMMISSION
    )
  end

  before do
    sign_in(admin)
  end

  describe "POST create" do
    before do
      post(
        :create,
        params: {
          locale: :de,
          accounting_transaction: {
            settlement_date: settlement_date,
            reference_number: reference_number,
            cost_center_id: cost_center.id,
            entity_id: product.id,
            entity_type: "Product",
            amount: transaction_amount,
            transaction_type: initial_comission_type
          }
        }
      )
    end

    it "creates a new accounting transaction" do
      transaction = Accounting::Transaction.find_by(
        reference_number: reference_number
      )

      expect(transaction.settlement_date).to eq(settlement_date)
      expect(transaction.cost_center).to eq(cost_center)
      expect(transaction.entity_id).to eq(product.id)
      expect(transaction.amount_cents).to eq(transaction_amount * 100)
    end

    it "shows notice message" do
      expect(controller).to(
        set_flash[:notice].to(
          I18n.t("admin.accounting.transactions.create.success")
        )
      )
    end
  end

  describe "PATCH update" do
    before do
      existing_transaction

      patch(
        :update,
        params: {
          locale: :de,
          id: existing_transaction.id,
          accounting_transaction: {
            settlement_date: settlement_date,
            reference_number: reference_number,
            cost_center_id: cost_center.id,
            entity_id: product.id,
            entity_type: "Product",
            amount: transaction_amount,
            transaction_type: reneval_comission_type
          }
        }
      )
    end

    it "updates an existing accounting transaction" do
      existing_transaction.reload

      expect(existing_transaction.settlement_date).to eq(settlement_date)
      expect(existing_transaction.cost_center).to eq(cost_center)
      expect(existing_transaction.entity_id).to eq(product.id)
      expect(existing_transaction.amount_cents).to eq(transaction_amount * 100)
      expect(existing_transaction.reference_number).to eq(reference_number)
      expect(existing_transaction.transaction_type).to(
        eq(ValueTypes::AccountingTransactionType::RENEWAL_COMMISSION)
      )
    end

    it "shows notice message" do
      expect(controller).to(
        set_flash[:notice].to(
          I18n.t("admin.accounting.transactions.update.success")
        )
      )
    end
  end

  describe "DELETE destroy" do
    before do
      existing_transaction

      delete(
        :destroy,
        params: {
          locale: :de,
          id: existing_transaction.id
        }
      )
    end

    it "deletes an existing accounting transaction" do
      expect(Accounting::Transaction.find_by(id: existing_transaction)).to be_nil
    end

    it "shows notice message" do
      expect(controller).to(
        set_flash[:notice].to(
          I18n.t("admin.accounting.transactions.destroy.success")
        )
      )
    end
  end
end

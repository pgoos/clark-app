# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finance::FondsFinanzTransactionImporter, type: :job do
  let(:test_file_path) { Rails.root.join("spec", "support", "assets", "fonds_finanz_payment.xlsx") }
  let(:asset) { Rack::Test::UploadedFile.new(test_file_path) }
  let!(:cost_center) { create(:cost_center, name: "Fonds Finanz") }

  def find_transaction_with(amount_cents, product_id)
    Accounting::Transaction.where(transaction_type: ValueTypes::AccountingTransactionType::INITIAL_COMMISSION,
                                  settlement_date: "2020-10-22",
                                  amount_cents: amount_cents,
                                  amount_currency: "EUR",
                                  reference_number: "1001",
                                  cost_center_id: cost_center.id,
                                  entity_type: "Product",
                                  entity_id: product_id)
  end

  context "with correct attributes" do
    let(:valid_mandate1) { create(:mandate, first_name: "male", last_name: "someone") }
    let(:valid_mandate2) { create(:mandate, first_name: "male", last_name: "someone else") }
    let(:valid_mandate3) { create(:mandate, first_name: "female", last_name: "someone") }
    let(:valid_mandate4) { create(:mandate, first_name: "female", last_name: "someone else") }
    let(:document) { create(:document, asset: asset, document_type: DocumentType.fonds_finanz_accounting_report) }

    let!(:product1) { create(:product, mandate: valid_mandate1, number: "5012") }
    let!(:product2) { create(:product, mandate: valid_mandate2, number: "5013") }
    let!(:product3) { create(:product, mandate: valid_mandate3, number: "5014") }
    let!(:product4) { create(:product, mandate: valid_mandate4, number: "5015") }

    it "create accounting_transactions" do
      expect {
        subject.perform(document.id)
      }.to change(Accounting::Transaction, :count).by(4)
      expect(find_transaction_with(121_230, product1.id)).to be_present
      expect(find_transaction_with(343_450, product2.id)).to be_present
      expect(find_transaction_with(642_320, product3.id)).to be_present
      expect(find_transaction_with(97_630, product4.id)).to be_present
    end
  end
end

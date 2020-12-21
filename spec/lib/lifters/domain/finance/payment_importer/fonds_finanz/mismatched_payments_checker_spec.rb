# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::FondsFinanz::MismatchedPaymentChecker do
  subject { described_class.new(mismatched_payment) }

  let(:mismatched_payment) do
    create(:mismatched_payment, first_name: "Manfred", last_name: "Greisel", amount_cents: "491184",
                                amount_currency: "EUR", settlement_date: "23.07.2019", cost_center: center_cost,
                                transaction_type: "initial_commission", number: "L140186215012",
                                reference_number: "2280173-19")
  end

  let!(:center_cost) { create(:cost_center, name: "Fonds Finanz") }
  let!(:mandate) { create(:mandate, first_name: "Manfred", last_name: "Greisel") }

  describe "#call" do
    context "product matched" do
      let!(:product) { create(:product, mandate: mandate, number: "L140186215012") }

      context "for payment with valid number" do
        it "process successful entries" do
          expect {
            subject.call
          }.to change { Accounting::Transaction.count }.by(1)

          expect { mismatched_payment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "for payment with invalid number (included special characters)" do
        let(:mismatched_payment) do
          create(:mismatched_payment, first_name: "Manfred", last_name: "Greisel", amount_cents: "491184",
                                      amount_currency: "EUR", settlement_date: "23.08.2019", cost_center: center_cost,
                                      transaction_type: "initial_commission", number: "L1  40%18) 62@ 15012",
                                      reference_number: "2280173-19")
        end

        it "process successful entries" do
          expect {
            subject.call
          }.to change { Accounting::Transaction.count }.by(1)

          expect { mismatched_payment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "product not matched" do
      it "process failed entries" do
        subject.call

        mismatched_payment.reload
        expect(mismatched_payment).not_to be_nil
        expect(mismatched_payment.first_name).to eq("Manfred")
        expect(mismatched_payment.last_name).to eq("Greisel")
        expect(mismatched_payment.reference_number).to eq("2280173-19")
        expect(mismatched_payment.number).to eq("L140186215012")
        expect(mismatched_payment.settlement_date).to eq("23.07.2019")
        expect(mismatched_payment.amount_cents).to eq(491_184)
        expect(mismatched_payment.amount_currency).to eq("EUR")
        expect(mismatched_payment.cost_center_id).to eq(center_cost.id)
      end
    end
  end
end

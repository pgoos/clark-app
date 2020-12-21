# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::FondsFinanz::Collection do
  def prepare_case(params)
    subject = described_class.new(["Vertragsnummer extern", "Kunde", "Abrechnungsnummer",
                                   "Abrechnungsdatum", "Summe in EUR", "Provisionsart"])
    subject.push(params)
    subject
  end

  let!(:center_cost) { create(:cost_center, name: "Fonds Finanz") }
  let!(:mandate) { create(:mandate, first_name: "Nanfred", last_name: "Vreisel") }
  let!(:product) { create(:product, mandate: mandate) }

  context "#initialize" do
    subject { described_class.new(["Kunde", "Summe in EUR"]) }

    it "has correct params_list" do
      expect(subject.instance_variable_get(:@param_list)).to eq(%i[name amount_euros])
    end
  end

  context "#push" do
    subject {
      described_class.new(["Vertragsnummer extern", "Kunde", "Abrechnungsnummer", "Abrechnungsdatum",
                           "Summe in EUR", "Provisionsart"])
    }

    let(:params) {
      ["L140186215012", "VN Greisel, Manfred", "2280173-19", "23.07.2019", "4911,84", "Abschlussprovision"]
    }

    let(:params2) {
      ["L140186215012", "VN Greisel, Manfred", "2280173-19", "23.07.2019", 4911.84, "Abschlussprovision"]
    }

    it "create the correct corresponding record" do
      subject.push(params)
      records = subject.instance_variable_get(:@records)
      expect(records.size).to eq(1)
      record = records.first
      expect(record.name).to eq("VN Greisel, Manfred")
      expect(record.first_name).to eq("Manfred")
      expect(record.last_name).to eq("Greisel")
      expect(record.amount_currency).to eq("EUR")
      expect(record.number).to eq("L140186215012")
      expect(record.reference_number).to eq("2280173-19")
      expect(record.settlement_date).to eq("23.07.2019")
      expect(record.amount_euros).to eq(4911.84)
      expect(record.amount_cents).to eq(491_184)
      expect(record.transaction_name).to eq("Abschlussprovision")
      expect(record.transaction_type).to eq("initial_commission")
      expect(record.cost_center_id).to eq(center_cost.id)
    end

    it "create the correct corresponding record" do
      subject.push(params2)
      records = subject.instance_variable_get(:@records)
      expect(records.size).to eq(1)
      record = records.first
      expect(record.name).to eq("VN Greisel, Manfred")
      expect(record.first_name).to eq("Manfred")
      expect(record.last_name).to eq("Greisel")
      expect(record.amount_currency).to eq("EUR")
      expect(record.number).to eq("L140186215012")
      expect(record.reference_number).to eq("2280173-19")
      expect(record.settlement_date).to eq("23.07.2019")
      expect(record.amount_euros).to eq(4911.84)
      expect(record.amount_cents).to eq(491_184)
      expect(record.transaction_name).to eq("Abschlussprovision")
      expect(record.transaction_type).to eq("initial_commission")
      expect(record.cost_center_id).to eq(center_cost.id)
    end
  end

  context "#validate!" do
    it "record move to failed_entries when does NOT match product mandate name" do
      object = prepare_case(["L140186215012", "VN Greisel, Manfred", "2280173-19", "23.07.2019", "4911,84",
                             "Abschlussprovision"])
      object.validate!
      expect(object.instance_variable_get(:@failed_entries).size).to eq(1)
    end

    it "record move to successful_entries when it is valid" do
      object = prepare_case([product.number, "VN #{product.mandate.last_name}, #{product.mandate.first_name}",
                             "2280173-19", "23.07.2019", "4911,84", "Abschlussprovision"])
      object.validate!
      expect(object.instance_variable_get(:@successful_entries).size).to eq(1)
    end
  end

  context "#process!" do
    it "process successful entries" do
      object = prepare_case([product.number, "VN #{product.mandate.last_name}, #{product.mandate.first_name}",
                             "2280173-19", "23.07.2019", "4911,84", "Abschlussprovision"])
      object.validate!
      expect(object.instance_variable_get(:@payments_repository))
        .to(receive(:append_payment_value_for_bulk_creation)
              .with(object.instance_variable_get(:@successful_entries).first))
      expect(object.instance_variable_get(:@payments_repository)).to receive(:persist_accounting_transactions!)
      object.process!
    end

    it "process failed entries" do
      object = prepare_case(["L140186215012", "VN Greisel, Manfred", "2280173-19", "23.07.2019", "4911,84",
                             "Abschlussprovision"])
      object.validate!
      object.process!

      mismatched_transaction = MismatchedPayment.last
      expect(mismatched_transaction).not_to be_nil
      expect(mismatched_transaction.first_name).to eq("Manfred")
      expect(mismatched_transaction.last_name).to eq("Greisel")
      expect(mismatched_transaction.reference_number).to eq("2280173-19")
      expect(mismatched_transaction.number).to eq("L140186215012")
      expect(mismatched_transaction.settlement_date).to eq("23.07.2019")
      expect(mismatched_transaction.amount.to_f).to eq(4911.84)
      expect(mismatched_transaction.transaction_type).to eq("initial_commission")
      expect(mismatched_transaction.cost_center_id).to eq(center_cost.id)
      expect(mismatched_transaction.reason.split(",")).to eq(
        %w[product_number_not_found product_is_not_valid]
      )
    end
  end
end

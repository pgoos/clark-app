# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::Repositories::PaymentRepository do
  it "has ATTRIBUTES constant with required attributes" do
    expect(described_class::ATTRIBUTES).to eq(%i[transaction_type cost_center_id reference_number settlement_date
                                                 amount_cents amount_currency entity_type entity_id])
  end

  def stringify_entry(entry)
    <<-VALUE
      ('#{entry.transaction_type}',
       #{entry.cost_center_id},
       '#{entry.reference_number}',
       '#{entry.settlement_date}',
       #{entry.amount_cents},
       '#{entry.amount_currency}',
       '#{entry.entity_type}',
       #{entry.entity_id},
       current_timestamp,
       current_timestamp)
    VALUE
  end

  context "#intialize" do
    subject { described_class.new }

    it "have empty values" do
      expect(subject.instance_variable_get(:@values)).to eq([])
    end

    it "have a connection" do
      expect(subject.instance_variable_get(:@connection)).not_to be_nil
    end

    it "have initialized column names from attributes" do
      expect(subject.instance_variable_get(:@attributes_to_query)).to eq(described_class::ATTRIBUTES.join(","))
    end
  end

  context "#append_payment_value_for_bulk_creation" do
    subject { described_class.new }

    let(:entry) {
      OpenStruct.new(transaction_type: "Something", cost_center_id: 1, reference_number: "123",
                     settlement_date: "2019-08-01", amount_cents: 2.1, amount_currency: "EUR",
                     entity_type: "Product", entity_id: 2)
    }

    it "add an element to values" do
      expect { subject.append_payment_value_for_bulk_creation(entry) }
        .to change { subject.instance_variable_get(:@values).size }.by(1)
      expect(subject.instance_variable_get(:@values).first.gsub(/[[:space:]]/, ""))
        .to eq(stringify_entry(entry).gsub(/[[:space:]]/, ""))
    end
  end

  context "#persist_accounting_transactions!" do
    subject { described_class.new }

    let(:cost_center) { create(:cost_center) }
    let(:entry) {
      OpenStruct.new(transaction_type: "Something", cost_center_id: cost_center.id, reference_number: "123",
                     settlement_date: "2019-08-01", amount_cents: 2.1, amount_currency: "EUR",
                     entity_type: "Product", entity_id: 2)
    }

    let(:tmp_product) { create(:product) }
    let(:transaction_record) {
      create(:accounting_transaction,
             cost_center_id: cost_center.id,
             entity_type: "Product",
             entity_id: tmp_product.id)
    }

    it "call create on connection object" do
      subject.append_payment_value_for_bulk_creation(entry)
      attrs = described_class::ATTRIBUTES.join(",")
      arg = <<~SQL
        INSERT INTO accounting_transactions(#{attrs}, created_at, updated_at) VALUES #{stringify_entry(entry)};
      SQL
      expect(subject).to receive(:create_query).and_return(arg)
      subject.persist_accounting_transactions!
      expect(subject.instance_variable_get(:@values)).to eq([])
    end

    it "will ignore duplicate entries" do
      duplicate_entry = OpenStruct.new(transaction_type: transaction_record.transaction_type.name.downcase,
                                       cost_center_id: cost_center.id,
                                       reference_number: transaction_record.reference_number,
                                       settlement_date: transaction_record.settlement_date,
                                       amount_cents: transaction_record.amount_cents,
                                       amount_currency: transaction_record.amount_currency,
                                       entity_type: "Product",
                                       entity_id: tmp_product.id)
      subject.append_payment_value_for_bulk_creation(duplicate_entry)
      expect { subject.persist_accounting_transactions! }.not_to change(Accounting::Transaction, :count)
    end
  end
end

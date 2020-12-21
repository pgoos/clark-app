# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentGapReport::Base, :integration do
  let(:admin) { create(:admin) }
  let(:old_policy) { create(:document, document_type: DocumentType.policy, created_at: 2.years.ago) }
  let(:current_policy) { create(:document, document_type: DocumentType.policy, created_at: 3.months.ago) }
  let(:mandate) do
    create(:mandate, first_name: "Manfred", last_name: "Greisel", documents: [old_policy, current_policy])
  end
  let(:offer) { create(:offer, opportunity: opportunity, mandate: mandate) }
  let(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product_id: product.id, admin: admin) }
  let!(:product) do
    create(:product, :with_sales_fee, mandate: mandate, number: "9333c1527178-1", contract_started_at: 1.day.ago,
                                      documents: [old_policy, current_policy], managed_by_pool: "Some admin")
  end
  let!(:offer_option) { create(:offer_option, offer: offer, product: product) }
  let!(:opportunity_completed_event) do
    create(:business_event, entity_id: opportunity.id, entity_type: "Opportunity", action: "update",
                            metadata: {"state" => {"new" => "completed", "old" => "in_creation"}})
  end
  let!(:product_cancellation_event) do
    create(:business_event, entity_id: product.id, entity_type: "Product", action: "update",
                            metadata: {"state" => {"new" => "canceled_by_customer", "old" => "in_creation"}})
  end

  let(:expected_csv_row) do
    [
      product.id.to_s,
      opportunity_completed_event.created_at.to_s,
      product.contract_started_at.to_s,
      "Manfred Greisel",
      product.plan.subcompany.name,
      product.managed_by_pool,
      "9333c1527178-1",
      current_policy.created_at.to_s,
      product_cancellation_event.created_at.to_s,
      "1",
      "200.0",
      "15.0",
      "200.0",
      "185.0",
      "5.0",
      "5.0",
      "-5.0",
      "0.0"
    ]
  end

  context "formatted as csv" do
    subject do
      Domain::Finance::PaymentGapReport::Base.new(
        from: 1.year.ago,
        to: 1.day.from_now,
        receiver: "example@clark.de",
        formatter: Domain::Finance::PaymentGapReport::Formatters::CSV
      )
    end

    before do
      create(:accounting_transaction, entity_id: product.id, entity_type: "Product", amount: 10)
      create(:accounting_transaction, entity_id: product.id, entity_type: "Product", amount: 5)
      create(:accounting_transaction, entity_id: product.id, entity_type: "Product", amount: 5,
                                      transaction_type: ValueTypes::AccountingTransactionType::MANAGEMENT_FEE)
    end

    it "creates report and sends it via email" do
      expect(Finance::ReportsMailer).to receive(:payment_gap_report).and_return(double(:mailer, deliver_now: true))
      subject.call

      report = CSV.read(subject.instance_variable_get(:@report_file))
      expect(report.first).to eq(
        [
          "Product_id",
          "opportunity_completed_date",
          "Versicherungsbeginn",
          "Kunde",
          "Gesellschaft",
          "Verwaltet über",
          "Versicherungsnummer",
          "Document_type date created at",
          "sales_cancel_date",
          "acquisition_commission_payouts_count",
          "total_sales_fee",
          "received_sales_fee",
          "canceled_sales_fee",
          "sales_fee_gap",
          "total_management_fee",
          "received_management_fee",
          "canceled_management_fee",
          "management_fee_gap"
        ]
      )

      expect(report.last).to eq(expected_csv_row)
    end
  end
end

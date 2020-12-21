# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payment gap csv integration test", :integration, type: :request do
  include ActiveJob::TestHelper
  let(:payment_gap_endpoint_permission) do
    Permission.find_by!("controller" => "admin/accounting_reports", "action" => "payment_gap_csv")
  end
  let(:admin) { create(:admin) }
  let(:current_policy) { create(:document, document_type: DocumentType.policy, created_at: 3.months.ago) }
  let(:mandate) do
    create(:mandate, first_name: "Manfred", last_name: "Greisel", documents: [current_policy])
  end
  let(:offer) { create(:offer, opportunity: opportunity, mandate: mandate) }
  let(:opportunity) { create(:opportunity, :completed, mandate: mandate, sold_product_id: product.id, admin: admin) }
  let!(:product) do
    create(:product, :with_sales_fee, mandate: mandate, number: "9333c1527178-1", managed_by_pool: "Some admin",
                                      documents: [current_policy], contract_started_at: contract_started_at)
  end
  let!(:offer_option) { create(:offer_option, offer: offer, product: product) }
  let!(:opportunity_completed_event) do
    create(:business_event, entity_id: opportunity.id, entity_type: "Opportunity", action: "update",
                            metadata: {"state" => {"new" => "completed", "old" => "in_creation"}})
  end
  let(:expected_csv_header) do
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
  end
  let(:payment_gap_email) { ActionMailer::Base.deliveries.last }
  let(:payment_gap_csv) { CSV.parse(payment_gap_email.attachments.first.body.raw_source) }

  before do
    allow(Features).to receive(:active?).with(Features::ACCOUNTING).and_return(true)
    admin.permissions << payment_gap_endpoint_permission
    sign_in admin
  end

  context "scenario 1: " do
    from = 1.year.ago.strftime("%d.%m.%Y")
    to = Time.zone.now.strftime("%d.%m.%Y")
    context "from #{from} to #{to}" do
      let(:contract_started_at) { 1.day.ago }
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
          "",
          "1",
          "200.0",
          "5.0",
          "0.0",
          "195.0",
          "5.0",
          "5.0",
          "0.0",
          "0.0"
        ]
      end

      before do
        create(:accounting_transaction, entity_id: product.id, entity_type: "Product", amount: 5)
        create(:accounting_transaction, entity_id: product.id, entity_type: "Product", amount: 5,
                                        transaction_type: ValueTypes::AccountingTransactionType::MANAGEMENT_FEE)
      end

      it "produces valid csv" do
        perform_enqueued_jobs do
          post "/de/admin/accounting_reports/payment_gap_csv", params: {
            accounting_report: {from: from, to: to}
          }
        end

        expect(flash[:success]).to eq "Der Export wird verarbeitet und in Kürze an deine E-Mail-Adresse geschickt."
        expect(payment_gap_email.to).to include(admin.email)
        expect(payment_gap_csv.first).to eq(expected_csv_header)
        expect(payment_gap_csv.last).to eq(expected_csv_row)
      end
    end
  end

  context "scenario 2: " do
    from = 1.year.ago.strftime("%d.%m.%Y")
    to = 3.days.ago.strftime("%d.%m.%Y")
    context "from #{from} to #{to}" do
      let(:contract_started_at) { 1.day.ago }

      it "produces valid csv" do
        perform_enqueued_jobs do
          post "/de/admin/accounting_reports/payment_gap_csv", params: {
            accounting_report: {from: from, to: to}
          }
        end

        expect(flash[:success]).to eq "Der Export wird verarbeitet und in Kürze an deine E-Mail-Adresse geschickt."
        expect(payment_gap_email.to).to include(admin.email)
        expect(payment_gap_csv.first).to eq(expected_csv_header)
        expect(payment_gap_csv.count).to eq(1)
      end
    end
  end
end

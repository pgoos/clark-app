# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractCancellationReminderJob, type: :job do
  let(:company_ident) { "company123" }
  let(:mandate) { double("Mandate") }
  let(:company) { double("Company", ident: company_ident) }
  let(:product) do
    double(
      id: 123,
      company: company,
      mandate: mandate,
      sold_by_us?: true,
      category_name: "Category Name",
      contract_ended_at?: true
    )
  end

  it "pushes the job in the correct queue" do
    expect {
      described_class.perform_later(product_id: product.id, channels: %w[email])
    }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  context "with valid product" do
    let(:expected_params) do
      {
        key: "contract_cancellation_reminder",
        mailer_options: {
          method: :notify_contract_cancellation_general_sold_by_us_known_end_date,
          params: [product.id]
        }
      }
    end

    it "builds the correct params to send out" do
      dummy = double(build_and_deliver: true)
      expect(Product).to receive(:find).with(product.id).and_return(product)
      expect(Domain::Products::ReminderParams).to receive(:call).with(product, "email").and_call_original
      expect(OutboundChannels::DistributionChannels).to receive(:new).with(expected_params).and_return(dummy)

      subject.perform(product_id: product.id, channels: %w[email])
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::StartSuhkProductTermination do
  subject(:start) { described_class }

  let(:product)     { object_double Product.new, company: company, opportunities: Opportunity.all }
  let(:company)     { object_double Company.new, info_email: "insurer@example.com" }
  let(:opportunity) { create :shallow_opportunity, state: "offer_phase" }
  let(:mailer)      { double :mailer, deliver_now: nil }

  before do
    allow(ProductMailer).to receive(:suhk_product_termination).and_return(mailer)
    allow(ProductMailer).to receive(:no_email_available_for_suhk_product_termination) \
      .and_return(mailer)
  end

  context "with insurer email" do
    it "sends email to the insurer" do
      expect(ProductMailer).to receive(:suhk_product_termination) \
        .with("insurer@example.com", product, opportunity)
      start.(product)
    end
  end

  context "without insurer email" do
    let(:company) { nil }

    it "sends email to the service" do
      expect(ProductMailer).to receive(:no_email_available_for_suhk_product_termination) \
        .with(product, opportunity)
      start.(product)
    end
  end

  context "without open opportunity" do
    let(:opportunity) { create :shallow_opportunity, state: "lost" }

    it "sends email with an empty opportunity" do
      expect(ProductMailer).to receive(:suhk_product_termination) \
        .with("insurer@example.com", product, nil)
      start.(product)
    end
  end
end

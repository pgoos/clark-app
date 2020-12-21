# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/exploration/interactors/check_contract_overview_eligibility"

RSpec.describe Customer::Constituents::Exploration::Interactors::CheckContractOverviewEligibility do
  subject do
    described_class.new(customer_repo: customer_repo, product_repo: product_repo, opportunity_repo: opportunity_repo)
  end

  let(:product_repo) { double :repo }
  let(:opportunity_repo) { double :repo }
  let(:customer_repo) { double :repo }
  let(:customer) { double :customer, id: 909 }
  let(:product) { double :product }
  let(:opportunity) { double :opportunity }

  context "when customer exists" do
    before do
      allow(customer_repo).to receive(:find).with(customer.id).and_return(customer)
    end

    context "and has at least one non state product" do
      it "returns true" do
        expect(product_repo)
          .to receive(:find_active_non_state_product)
          .with(customer.id).and_return(product)
        result = subject.call(customer.id)
        expect(result).to be_successful
        expect(result.eligible).to eq true
      end
    end

    context "and has at least one opportunity" do
      it "returns true" do
        expect(opportunity_repo).to receive(:find_by_customer).with(customer.id).and_return(opportunity)
        expect(product_repo)
          .to receive(:find_active_non_state_product)
          .with(customer.id).and_return(nil)
        result = subject.call(customer.id)
        expect(result).to be_successful
        expect(result.eligible).to eq true
      end
    end

    context "and does not have opportunity or product" do
      it "returns false" do
        expect(opportunity_repo).to receive(:find_by_customer).with(customer.id).and_return(nil)
        expect(product_repo)
          .to receive(:find_active_non_state_product)
          .with(customer.id).and_return(nil)
        result = subject.call(customer.id)
        expect(result).to be_successful
        expect(result.eligible).to eq false
      end
    end
  end

  context "when customer doesn't exist" do
    it "returns result with failure" do
      expect(customer_repo).to receive(:find).with(customer.id).and_return(nil)
      result = subject.call(customer.id)
      expect(result).to be_failure
    end
  end
end

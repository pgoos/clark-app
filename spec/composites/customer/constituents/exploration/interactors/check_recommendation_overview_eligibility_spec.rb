# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/exploration/interactors/check_recommendation_overview_eligibility"

RSpec.describe Customer::Constituents::Exploration::Interactors::CheckRecommendationOverviewEligibility do
  subject do
    described_class.new(
      customer_repo: customer_repo,
      questionnaire_response_repo: questionnaire_response_repo
    )
  end

  let(:questionnaire_response_repo) { double :repo }
  let(:customer_repo) { double :repo }
  let(:customer) { double :customer, id: 909 }
  let(:questionnaire_response) { double :questionnaire_response }

  context "when customer exists" do
    before do
      allow(customer_repo).to receive(:find).with(customer.id).and_return(customer)
    end

    context "and has at least one demandcheck questionnaire response" do
      it "returns true" do
        expect(questionnaire_response_repo)
          .to receive(:find_by_customer)
          .with(customer.id, demandcheck: true).and_return(questionnaire_response)
        result = subject.call(customer.id)
        expect(result).to be_successful
        expect(result.eligible).to eq true
      end
    end

    context "and does not have demandcheck questionnaire response" do
      it "returns false" do
        expect(questionnaire_response_repo)
          .to receive(:find_by_customer)
          .with(customer.id, demandcheck: true).and_return(nil)
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

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::Plans::Export do
  subject { described_class.new(path: "") }

  let(:plan) do
    create(:plan)
  end

  let(:offer_rule_data) do
    {
      "rule1" => [plan.ident]
    }
  end

  before do
    allow_any_instance_of(described_class).to receive(:save_data)
      .and_return(nil)

    allow_any_instance_of(Domain::OfferGeneration::MatrixRepository).to receive(:plans_with_automations)
      .and_return([plan])

    allow_any_instance_of(Domain::OfferGeneration::MatrixRepository).to receive(:rules_with_plans)
      .and_return(offer_rule_data)
  end

  describe "#call" do
    let(:expected_data) do
      a_hash_including(
        companies: a_hash_including(
          plan.company.ident
        ),
        subcompanies: a_hash_including(
          plan.subcompany.ident
        ),
        plans: a_hash_including(
          plan.ident => a_hash_including(
            "ident" => plan.ident,
            "company_id" => plan.company.ident,
            "subcompany_id" => plan.subcompany.ident,
            "category_id" => plan.category.ident
          )
        )
      )
    end

    it "returns data" do
      expect(subject.call).to match(expected_data)
    end
  end
end

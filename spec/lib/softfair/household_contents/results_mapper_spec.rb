# frozen_string_literal: true

require "rails_helper"
require "softfair/household_contents/results_mapper"
require "softfair/util/result_mapping"

RSpec.describe Softfair::HouseholdContents::ResultsMapper do
  include Softfair::Util::ResultMapping
  let(:mapper_instance) { described_class.new(candidate_context) }
  let(:subcompany) { create(:subcompany, softfair_ids: [softfair_result["nGslID_01"]]) }
  let(:category) { create(:category_hr) }
  let(:plan) do
    create(
      :plan,
      name: softfair_result["cTrfWrk"].strip,
      external_id: softfair_result["nTrfWrkID"].strip,
      subcompany: subcompany,
      category: category
    )
  end

  let(:softfair_result) do
    sample_xml_response = File.open("#{FIXTURE_DIR}/household/softfair_response.xml")
    nested_hash_value(Hash.from_xml(sample_xml_response), "result")[0]
  end
  let(:candidate_context) do
    Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext.new(category)
  end

  before do
    candidate_context.request = File.open("#{FIXTURE_DIR}/household/valid_request.xml")
    candidate_context.comparison_results = [[plan, softfair_result]]
  end

  context "plan exists" do
    it "sets the product_attributes context" do
      mapper_instance.generate_offer_plans

      attributes = candidate_context.product_attributes[plan.ident]
      expect(attributes).to include(premium_price_cents: (softfair_result["nPrm_j_lsv"].to_f * 100))
      expect(attributes).to include(premium_price_currency: "EUR")
      expect(attributes).to include(premium_period: "year")

      expected_money = ::Money.new(424_242 * 100, "EUR")
      actual_money = attributes[:coverages]["fhrrd1f2777d12624a43a"].to_monetized
      expect(actual_money).to eq expected_money
    end
  end
end

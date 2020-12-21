# frozen_string_literal: true

require "rails_helper"
require "softfair/household_contents/results_filter"

RSpec.describe Softfair::HouseholdContents::ResultsFilter do
  let(:filter) { subject }
  let(:candidate_context) do
    instance_double(Domain::OfferGeneration::HouseholdContents::HouseholdAutomationContext)
  end

  before do
    allow(candidate_context).to receive(:debug_info).and_return({})
  end

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(filter).to respond_to(:filter_results) }
    end

    context "executes methods correctly" do
      let(:category) { create(:category_hr) }

      before do
        allow(candidate_context).to receive(:category).and_return(category)
      end

      context "#filter_results" do
        let(:subcompany) { create(:subcompany, softfair_ids: [3080]) }
        let(:xml) { File.open("#{FIXTURE_DIR}/household/softfair_response.xml").read }
        let(:expected_comparison_results) do
          [
            [plan, { "diffgr:id" => "result87", "msdata:rowOrder" => "42", "nTrfWrkID" => "3310", "nGslID_01" => "3080" }]
          ]
        end
        let(:plan) do
          create(
            :plan,
            external_id: 3310,
            subcompany: subcompany,
            category: category
          )
        end

        it "does nothing if the response is empty" do
          allow(candidate_context).to receive(:response)
          allow(candidate_context).to receive(:comparison_results)
          filter.filter_results(candidate_context)

          expect(candidate_context.comparison_results).to be_nil
        end

        it "returns only white listed comparison results array from softfair response" do
          allow(candidate_context).to receive(:response) { xml }
          allow(candidate_context).to receive(:mandate) { double("Mandate", id: 1) }

          expect(candidate_context).to receive(:comparison_results=).with(expected_comparison_results)

          filter.filter_results(candidate_context)
        end

        context "when there is no plan with external id" do
          it "returns empty" do
            allow(candidate_context).to receive(:response) { xml }
            allow(candidate_context).to receive(:mandate) { double("Mandate", id: 1) }

            expect(candidate_context).to receive(:comparison_results=).with([])

            filter.filter_results(candidate_context)
          end
        end

        context "when an unknown error happens" do
          it "thorws an error with more details" do
            allow(candidate_context).to receive(:response) { xml }
            allow(candidate_context).to receive(:mandate) { double("Mandate", id: 1) }
            allow(Subcompany).to receive(:by_softfair_id).and_raise("Whoops!")

            expect {
              filter.filter_results(candidate_context)
            }.to raise_error(Softfair::HouseholdContents::Error, "Softfair result filter failed: Whoops!")
          end
        end
      end
    end
  end
end

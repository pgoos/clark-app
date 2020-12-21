# frozen_string_literal: true

require "rails_helper"

require "composites/sales/constituents/opportunity/repositories/opportunity_repository"
require "composites/sales/constituents/opportunity/interactors/update_opportunity_details"

RSpec.describe Sales::Constituents::Opportunity::Interactors::UpdateOpportunityDetails do
  let(:interactor) { described_class.new(opportunities_repo: double_opportunities_repo) }
  let(:double_opportunities_repo) do
    instance_double(Sales::Constituents::Opportunity::Repositories::OpportunityRepository)
  end

  describe "#call" do
    let(:opportunity_id) { 1 }
    let(:customer_id) { 1 }

    context "when preferred insurance start is later" do
      let(:selected_date) { Date.new(2020, 8, 7) }
      let(:expected_attributes) { { "preferred_insurance_start_date" => selected_date } }
      let(:attributes) do
        {
          "preferred_insurance_start" =>  "later",
          "preferred_insurance_start_date" => selected_date,
          "has_previous_damages" => false
        }
      end

      it "calls opportunities_repository" do
        expect(double_opportunities_repo)
          .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

        result = interactor.call(customer_id, opportunity_id, attributes)
        expect(result.ok?).to be true
      end

      context "but no preffered_insurance_start_date is passed in" do
        let(:attributes) do
          {
            "preferred_insurance_start" =>  "later",
            "has_previous_damages" => false
          }
        end

        it "does not call repository" do
          expect(double_opportunities_repo).not_to receive(:update!)

          interactor.call(customer_id, opportunity_id, attributes)
        end

        it "raises an exception" do
          result = interactor.call(customer_id, opportunity_id, attributes)
          expect(result.error?).to be true
        end
      end
    end

    context "when preferred insurance start is next-working-day" do
      shared_examples "a valid next working day" do
        let(:expected_attributes) { { "preferred_insurance_start_date" => next_working_day } }
        let(:attributes) do
          {
            "preferred_insurance_start" =>  "next-working-day",
            "has_previous_damages" => false
          }
        end

        before { allow(Date).to receive(:tomorrow).and_return tomorrow }

        it "calls opportunities_repository" do
          expect(double_opportunities_repo)
            .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

          interactor.call(customer_id, opportunity_id, attributes)
        end

        it "returns a success result" do
          allow(double_opportunities_repo)
            .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

          result = interactor.call(customer_id, opportunity_id, attributes)
          expect(result.ok?).to be true
        end
      end

      context "and tomorrow is on weekday" do
        let(:tomorrow) { Date.new(2020, 8, 5) }
        let(:next_working_day) { Date.new(2020, 8, 5) }

        it_behaves_like "a valid next working day"
      end

      context "and tomorrow is on weekend" do
        let(:tomorrow) { Date.new(2020, 8, 8) }
        let(:next_working_day) { Date.new(2020, 8, 10) }

        it_behaves_like "a valid next working day"
      end

      context "and tomorrow is on weekend and next monday is holiday" do
        let(:tomorrow) { Date.new(2020, 8, 8) }
        let(:holiday) { Date.new(2020, 8, 10) }
        let(:next_working_day) { Date.new(2020, 8, 11) }

        before do
          stub_const("Sales::Constituents::Opportunity::Interactors::UpdateOpportunityDetails::HOLIDAYS", [holiday])
        end

        it_behaves_like "a valid next working day"
      end
    end

    context "when has_previous_damages is true" do
      let(:previous_damages) { "Lorem ipsum dolor sit amet." }
      let(:preferred_date) { Date.new(2020, 8, 4) }
      let(:expected_attributes) do
        {
          "previous_damages" => previous_damages,
          "preferred_insurance_start_date" => preferred_date
        }
      end
      let(:attributes) do
        {
          "preferred_insurance_start" => "later",
          "preferred_insurance_start_date" => preferred_date,
          "has_previous_damages" => true,
          "previous_damages" => previous_damages
        }
      end

      it "calls opportunities_repository" do
        expect(double_opportunities_repo)
          .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

        result = interactor.call(customer_id, opportunity_id, attributes)
        expect(result.ok?).to be true
      end

      context "but previous_damages is not passed in" do
        let(:attributes) do
          {
            "preferred_insurance_start" => "later",
            "preferred_insurance_start_date" => preferred_date,
            "has_previous_damages" => true
          }
        end

        it "does not call repository" do
          expect(double_opportunities_repo).not_to receive(:update!)

          interactor.call(customer_id, opportunity_id, attributes)
        end

        it "raises an exception" do
          result = interactor.call(customer_id, opportunity_id, attributes)
          expect(result.error?).to be true
        end
      end
    end

    context "when has_previous_damages is false" do
      let(:preferred_date) { Date.new(2020, 8, 4) }
      let(:expected_attributes) do
        {
          "preferred_insurance_start_date" => preferred_date
        }
      end
      let(:attributes) do
        {
          "preferred_insurance_start" => "later",
          "preferred_insurance_start_date" => preferred_date,
          "has_previous_damages" => false
        }
      end

      it "calls opportunities_repository" do
        expect(double_opportunities_repo)
          .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

        result = interactor.call(customer_id, opportunity_id, attributes)
        expect(result.ok?).to be true
      end

      context "but previous_damages is passed in" do
        let(:attributes) do
          {
            "preferred_insurance_start" => "later",
            "preferred_insurance_start_date" => preferred_date,
            "has_previous_damages" => false,
            "previous_damages" => "Text text text"
          }
        end

        it "removes it" do
          expect(double_opportunities_repo)
            .to receive(:update!).with(customer_id, opportunity_id, expected_attributes).and_return(true)

          result = interactor.call(customer_id, opportunity_id, attributes)
          expect(result.ok?).to be true
        end
      end
    end
  end
end

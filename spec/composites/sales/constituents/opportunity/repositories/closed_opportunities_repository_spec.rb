# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository, :integration do
  let(:repository) { described_class.new }
  let(:beginning_of_a_month) { DateTime.new(2010, 4, 1, 0, 0, 0) }

  describe "#closed_opportunities_for!" do
    def create_opportunity_with_case(state:,
                                     dates: {},
                                     assign_event: :assign,
                                     admin: create(:admin),
                                     product_data: {})
      assigned_at = dates[:assigned_at] || beginning_of_a_month
      closed_at = dates[:closed_at] || assigned_at + 1.day

      closed_event = case state
                     when :complete then :complete_opportunity_business_event
                     when :lost then :cancel_opportunity_business_event
                     end

      opportunity = create_opportunity(state: state, admin: admin, product_data: product_data)
      create_business_event_with_case(entity: opportunity, created_at: assigned_at, event: assign_event)
      create_business_event_with_case(entity: opportunity, created_at: closed_at, event: closed_event) if closed_event
      opportunity
    end

    def create_business_event_with_case(entity:, created_at:, event:)
      event = case event
              when :update then :update_admin_opportunity_business_event
              when :assign then :assign_opportunity_business_event
              when :create then :create_opportunity_business_event
              else event
              end
      create(event, :with_entity_opportunity, created_at: created_at, entity: entity)
    end

    def create_opportunity(state:, admin:, product_data:)
      opportunity_trait = case state
                          when :complete then :completed
                          when :lost then :lost
                          else :offer_phase
                          end
      sold_product = create_sold_product(price: product_data[:price] || Faker::Number.number(digits: 2),
                                         payouts_count: product_data[:payouts_count] || Faker::Number.number(digits: 1))
      create(:opportunity, opportunity_trait, admin: admin, sold_product: sold_product)
    end

    def create_sold_product(price:, payouts_count:)
      create(:product,
             acquisition_commission_price_cents: price,
             acquisition_commission_payouts_count: payouts_count)
    end

    describe "#find the correct data" do
      it "finds opportunities only with lost or completed state and have business_event " \
      "with action cancel or complete, for all admins if nothing passed" do
        lost_opportunity = create_opportunity_with_case(state: :lost)
        complete_opportunity = create_opportunity_with_case(state: :complete)
        create_opportunity_with_case(state: :offer_phase)
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunities_in_results = results.values.flatten.map { |opportunity| opportunity[:id] }.sort
        expect(opportunities_in_results).to eq([lost_opportunity.id, complete_opportunity.id].sort)
      end

      it "finds opportunities for the passed admins if passed any" do
        first_lost_opportunity = create_opportunity_with_case(state: :lost)
        second_lost_opportunity = create_opportunity_with_case(state: :lost)
        create_opportunity_with_case(state: :lost)
        results = repository.closed_opportunities_for(
          beginning_of_a_month,
          [first_lost_opportunity.admin_id, second_lost_opportunity.admin_id],
          nil
        )
        opportunities_in_results = results.values.flatten.map { |opportunity| opportunity[:id] }.sort
        expect(opportunities_in_results).to eq([first_lost_opportunity.id, second_lost_opportunity.id].sort)
      end

      it "finds opportunities closed in the same month and year passed in date" do
        first_lost_opportunity = create_opportunity_with_case(state: :lost)
        second_lost_opportunity = create_opportunity_with_case(
          state: :complete,
          dates: { assigned_at: beginning_of_a_month - 2.months, closed_at: beginning_of_a_month + 15.days }
        )
        create_opportunity_with_case(
          state: :complete,
          dates: { assigned_at: beginning_of_a_month - 2.months, closed_at: beginning_of_a_month - 1.month }
        )
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunities_in_results = results.values.flatten.map { |opportunity| opportunity[:id] }.sort
        expect(opportunities_in_results).to eq([first_lost_opportunity.id, second_lost_opportunity.id].sort)
      end

      it "finds opportunities for the passed categories if passed any" do
        first_lost_opportunity = create_opportunity_with_case(state: :lost)
        second_lost_opportunity = create_opportunity_with_case(state: :lost)
        create_opportunity_with_case(state: :lost)
        results = repository.closed_opportunities_for(
          beginning_of_a_month,
          [],
          [first_lost_opportunity.category_id, second_lost_opportunity.category_id]
        )
        opportunities_in_results = results.values.flatten.map { |opportunity| opportunity[:id] }.sort
        expect(opportunities_in_results).to eq([first_lost_opportunity.id, second_lost_opportunity.id].sort)
      end
    end

    describe "#build_closed_opportunity_entity" do
      it "returns with the correct attributes" do
        assigned_at = beginning_of_a_month + 10.days
        closed_at = beginning_of_a_month + 12.days
        opportunity = create_opportunity_with_case(
          state: :complete,
          dates: { assigned_at: assigned_at, closed_at: closed_at }
        )
        product = opportunity.sold_product
        produce_price_in_euro = product.acquisition_commission_price_cents / 100.0
        expected_revenue = produce_price_in_euro * product.acquisition_commission_payouts_count
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunity_in_results = results.values.flatten.first
        expect(opportunity_in_results[:id]).to eq(opportunity.id)
        expect(opportunity_in_results[:consultant_id]).to eq(opportunity.admin_id)
        expect(opportunity_in_results[:assigned_at]).to eq(assigned_at.to_date)
        expect(opportunity_in_results[:closed_at]).to eq(closed_at.to_date)
        expect(opportunity_in_results[:revenue]).to eq(expected_revenue)
        expect(opportunity_in_results[:closed_successfully]).to be_truthy
      end

      it "consider update admin_id action as an assign" do
        assigned_at = beginning_of_a_month + 10.days
        create_opportunity_with_case(state: :complete, assign_event: :update, dates: { assigned_at: assigned_at })
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunity_in_results = results.values.flatten.first
        expect(opportunity_in_results[:assigned_at]).to eq(assigned_at)
      end

      it "consider create action as an assign" do
        assigned_at = beginning_of_a_month + 10.days
        create_opportunity_with_case(state: :complete, assign_event: :create, dates: { assigned_at: assigned_at })
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunity_in_results = results.values.flatten.first
        expect(opportunity_in_results[:assigned_at]).to eq(assigned_at)
      end

      it "priorities between assign, update admin_id and create actions based on created_at" do
        create_at = beginning_of_a_month + Faker::Number.between(from: 10, to: 20).days
        opportunity = create_opportunity_with_case(
          state: :complete, assign_event: :create,
          dates: {
            assigned_at: create_at,
            closed_at: beginning_of_a_month + 29.days
          }
        )
        assigned_at = beginning_of_a_month + Faker::Number.between(from: 10, to: 20).days
        create_business_event_with_case(entity: opportunity, created_at: assigned_at, event: :assign)
        update_at = beginning_of_a_month + Faker::Number.between(from: 10, to: 20).days
        create_business_event_with_case(entity: opportunity, created_at: update_at, event: :update)
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunity_in_results = results.values.flatten.first
        expect(opportunity_in_results[:assigned_at]).to eq([create_at, assigned_at, update_at].max.to_date)
      end

      it "returns closed_successfully with false if lost" do
        create_opportunity_with_case(state: :lost)
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunity_in_results = results.values.flatten.first
        expect(opportunity_in_results[:closed_successfully]).to be_falsey
      end
    end

    describe "#build_collective_attributes" do
      it "calculates cell allocation correctly use same case as in AOA README" do
        first_opportunity = create_opportunity_with_case(state: :complete,
                                                         dates: { assigned_at: beginning_of_a_month - 2.days,
                                                         closed_at: beginning_of_a_month + 3.days },
                                                         product_data: { price: 300_000,
                                                         payouts_count: 1 })
        admin = first_opportunity.admin
        second_opportunity = create_opportunity_with_case(state: :lost,
                                                         dates: { assigned_at: beginning_of_a_month + 1.day,
                                                         closed_at: beginning_of_a_month + 4.days },
                                                          admin: admin,
                                                          product_data: { price: 300_000,
                                                          payouts_count: 1 })
        third_opportunity = create_opportunity_with_case(state: :complete,
                                                          dates: { assigned_at: beginning_of_a_month - 1.day,
                                                          closed_at: beginning_of_a_month + 2.days },
                                                         admin: admin,
                                                         product_data: { price: 300_000,
                                                         payouts_count: 1 })
        forth_opportunity = create_opportunity_with_case(state: :complete,
                                                         dates: { assigned_at: beginning_of_a_month + 2.days,
                                                         closed_at: beginning_of_a_month + 5.days },
                                                         admin: admin,
                                                         product_data: { price: 300_000,
                                                         payouts_count: 1 })
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        opportunities_in_results = results.values.flatten
        expected_avgs = [2.5, 3, 2.75, 2.5]
        expected_revenue = [3000, 6000, 0, 6000]
        [first_opportunity, second_opportunity,
         third_opportunity, forth_opportunity].each_with_index do |generated_opportunity, idx|
          opportunity_result = opportunities_in_results
                               .find { |opportunity| opportunity[:id] == generated_opportunity.id }
          expect(opportunity_result[:avg_open_opportunities]).to eq(expected_avgs[idx])
          expect(opportunity_result[:generated_revenue_so_far]).to eq(expected_revenue[idx])
        end
      end
    end

    context "output format" do
      it "returns hash where admin_ids are keys and opportunities are values" do
        admin1_opportunity1 = create_opportunity_with_case(state: :complete)
        admin1_opportunity2 = create_opportunity_with_case(state: :complete, admin: admin1_opportunity1.admin)
        admin2_opportunity1 = create_opportunity_with_case(state: :complete)
        results = repository.closed_opportunities_for(beginning_of_a_month, [], [])
        expect(results.keys.sort).to eq([admin1_opportunity1.admin_id, admin2_opportunity1.admin_id].sort)
        results_admin1_opportunity_ids = results[admin1_opportunity1.admin_id]
                                         .map { |opportunity| opportunity[:id] }.sort
        expect(results_admin1_opportunity_ids).to eq([admin1_opportunity1.id, admin1_opportunity2.id].sort)
        results_admin2_opportunity_ids = results[admin2_opportunity1.admin_id]
                                         .map { |opportunity| opportunity[:id] }
        expect(results_admin2_opportunity_ids).to eq([admin2_opportunity1.id])
      end

      it "returns hash where all admin_ids passed to it are keys and opportunities" \
         "are values or nil if admin doesn't have any opportunity" do
        admin1_opportunity1 = create_opportunity_with_case(state: :complete)
        admin2 = create(:admin)
        results = repository.closed_opportunities_for(beginning_of_a_month,
                                                      [admin1_opportunity1.admin_id, admin2.id],
                                                      nil)
        expect(results.keys.sort).to eq([admin1_opportunity1.admin_id, admin2.id].sort)
        results_admin1_opportunity_ids = results[admin1_opportunity1.admin_id]
                                         .map { |opportunity| opportunity[:id] }.sort
        expect(results_admin1_opportunity_ids).to eq([admin1_opportunity1.id])
        expect(results[admin2.id]).to be_nil
      end

      it "excludes opportunities which have closed happened before assigned" do
        opportunity = create_opportunity_with_case(state: :complete,
                                                   dates: { assigned_at: beginning_of_a_month + 4.days,
                                                            closed_at: beginning_of_a_month + 1.day })
        admin_id = opportunity.admin_id
        results = repository.closed_opportunities_for(beginning_of_a_month, [admin_id], nil)
        expect(results.keys).to eq([admin_id])
        expect(results[admin_id]).to be_nil
      end
    end
  end
end

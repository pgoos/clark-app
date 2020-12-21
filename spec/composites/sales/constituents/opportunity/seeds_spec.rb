# frozen_string_literal: true

require "rails_helper"
require "composites/sales/constituents/opportunity/seed"

RSpec.describe Sales::Constituents::Opportunity::Seed do
  subject(:seeds) { described_class.new }

  let(:open_leads_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::OPEN_LEADS_BUCKETS
  end
  let(:revenue_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::REVENUE_BUCKETS
  end

  let!(:category) { create :category, ident: "3d439696" }

  it "includes Utils::Seeder in included modules" do
    expect(seeds).to be_kind_of Utils::Seeder
  end

  it "is a Utils::Seeder::PreventProductionUsage" do
    expect(seeds).to be_kind_of Utils::Seeder::PreventProductionUsage
  end

  describe "#seed_custom_opportunity_case", :integration do
    def assert_opportunity_presence(result, state)
      opportunity_exists = Opportunity.exists?(id: result[:opportunity_id],
                                               sold_product_id: result[:product_id],
                                               admin_id: result[:admin_id],
                                               state: state)
      expect(opportunity_exists).to be_truthy
    end

    def assert_product_presence(result)
      expect(Product.exists?(id: result[:product_id])).to be_truthy
    end

    def assert_assign_event_presence(assign_event, result)
      assign_event_exists = BusinessEvent.exists?(id: result[:business_events][:assign],
                                                  action: assign_event.to_s,
                                                  entity_id: result[:opportunity_id],
                                                  entity_type: "Opportunity",
                                                  person_id: result[:admin_id],
                                                  person_type: "Admin")
      expect(assign_event_exists).to be_truthy
    end

    def assert_close_event_presence(result, state)
      close_action = state == :completed ? "complete" : "cancel"
      close_event_exists = BusinessEvent.exists?(id: result[:business_events][:close],
                                                 action: close_action,
                                                 entity_id: result[:opportunity_id],
                                                 entity_type: "Opportunity",
                                                 person_id: result[:admin_id],
                                                 person_type: "Admin")
      expect(close_event_exists).to be_truthy
    end

    %i[completed lost].each do |state|
      %i[assign create update].each do |assign_event|
        it "creates an opportunity of the state #{state} assigned with #{assign_event} with all required data" do
          result = seeds.seed_custom_opportunity_case(state: state, assign_event: assign_event)

          assert_opportunity_presence(result, state)
          assert_product_presence(result)
          assert_assign_event_presence(assign_event, result)
          assert_close_event_presence(result, state)
        end
      end
    end
  end

  describe "#seed_monthly_admin_performance", :integration do
    it "creates 'monthly_admin_performances' row" do
      expect { seeds.seed_monthly_admin_performance }.to change(MonthlyAdminPerformance, :count).by(1)
    end

    it "creates 'monthly_admin_performances' row with valid attributes" do
      result = seeds.seed_monthly_admin_performance
      consultant_id = result[:admin_id]

      monthly_admin_performance_row = MonthlyAdminPerformance.find_by_id(result[:monthly_admin_performance_ids][0])

      expect(monthly_admin_performance_row[:consultant_id]).to eq(consultant_id)
      expect(monthly_admin_performance_row[:open_opportunities]).to be_present
      expect(monthly_admin_performance_row[:revenue]).to be_present
      expect(monthly_admin_performance_row[:calculation_date]).to be_present
      expect(monthly_admin_performance_row[:performance_level]).to be_a_kind_of(Hash)

      expect(monthly_admin_performance_row[:open_opportunities_category_counts]).to be_present
      expect(monthly_admin_performance_row[:open_opportunities_category_counts]).to be_a_kind_of(Hash)

      expect(monthly_admin_performance_row[:performance_matrix]).to be_present
      expect(monthly_admin_performance_row[:performance_matrix]).to be_a_kind_of(Hash)

      open_leads_buckets.map(&:to_s).each do |performance|
        revenue_buckets.map(&:to_s).each do |rank|
          expect(monthly_admin_performance_row[:performance_matrix][performance][rank]).to be_present
          expect(monthly_admin_performance_row[:performance_matrix][performance][rank]).to be_a_kind_of(Float)
        end
      end
    end

    it "returns an appropriate result" do
      result = seeds.seed_monthly_admin_performance(size: 10)

      expect(result[:admin_id]).to be_present
      expect(result[:monthly_admin_performance_ids].count).to eq(10)
    end
  end
end

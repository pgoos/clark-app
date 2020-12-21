# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix do
  let(:beginning_of_a_month) { DateTime.new(2010, 4, 1, 0, 0, 0) }
  let(:consultant_id) { [] }
  let(:category_id) { [] }

  def generate_opportunity(closed_successfully: false,
                           avg_open_opportunities: Faker.number.between(1, 3),
                           generated_revenue_so_far: Faker.number.between(10_000.0, 30_000.0))
    {
      closed_successfully: closed_successfully,
      avg_open_opportunities: avg_open_opportunities,
      generated_revenue_so_far: generated_revenue_so_far
    }
  end

  describe "#call" do
    it "calculates performance matrix correctly use same case as in AOA README" do
      expect_any_instance_of(
        Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
      ).to receive(:closed_opportunities_for).with(beginning_of_a_month, consultant_id, category_id)
                                             .and_return(
                                               {
                                                 1 => [
                                                   generate_opportunity(closed_successfully: true,
                                                                        avg_open_opportunities: 2.5,
                                                                        generated_revenue_so_far: 3000),
                                                   generate_opportunity(closed_successfully: false,
                                                                        avg_open_opportunities: 3,
                                                                        generated_revenue_so_far: 6000),
                                                   generate_opportunity(closed_successfully: true,
                                                                        avg_open_opportunities: 2.75,
                                                                        generated_revenue_so_far: 0),
                                                   generate_opportunity(closed_successfully: true,
                                                                        avg_open_opportunities: 2.5,
                                                                        generated_revenue_so_far: 6000)
                                                 ]
                                               }
                                             )
      monthly_performance_matrix = subject.call(beginning_of_a_month).monthly_performance_matrix

      expect(monthly_performance_matrix.keys.sort).to eq([1])
      monthly_performance_matrix.each do |(consultant_id, performance_matrix)|
        expect(consultant_id).to eq(1)
        expect(performance_matrix.keys.sort).to eq(described_class::OPEN_LEADS_BUCKETS)
        performance_matrix.each do |(open_leads_bucket, revenue_buckets)|
          expect(revenue_buckets.keys.sort).to eq(described_class::REVENUE_BUCKETS)
          revenue_buckets.each do |revenue_bucket, conversion_rate|
            if open_leads_bucket == 10 && revenue_bucket == 3000
              expect(conversion_rate).to eq(1.0)
              next
            end
            if open_leads_bucket == 10 && revenue_bucket == 9000
              expect(conversion_rate).to eq(0.5)
              next
            end
            expect(conversion_rate).to eq(0.75)
          end
        end
      end
    end

    it "returns empty performance matrix with the same structure if no opportunities found for the passed consultant" do
      expect_any_instance_of(
        Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
      ).to receive(:closed_opportunities_for).with(beginning_of_a_month, 1, category_id)
                                             .and_return({ 1 => nil })
      monthly_performance_matrix = subject.call(beginning_of_a_month, 1).monthly_performance_matrix
      monthly_performance_matrix.each do |(consultant_id, performance_matrix)|
        expect(consultant_id).to eq(1)
        expect(performance_matrix.keys.sort).to eq(described_class::OPEN_LEADS_BUCKETS)
        performance_matrix.each do |(_open_leads_bucket, revenue_buckets)|
          expect(revenue_buckets.keys.sort).to eq(described_class::REVENUE_BUCKETS)
          revenue_buckets.each do |_revenue_bucket, conversion_rate|
            expect(conversion_rate).to be_nil
          end
        end
      end
    end

    it "returns 0 everywhere is the consultant never successfully closed an opportunity" do
      expect_any_instance_of(
        Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
      ).to receive(:closed_opportunities_for).with(beginning_of_a_month, consultant_id, category_id)
                                             .and_return(
                                               {
                                                 1 => [
                                                   generate_opportunity(closed_successfully: false,
                                                                        avg_open_opportunities: 3,
                                                                        generated_revenue_so_far: 6000)
                                                 ]
                                               }
                                             )
      monthly_performance_matrix = subject.call(beginning_of_a_month).monthly_performance_matrix

      expect(monthly_performance_matrix.keys.sort).to eq([1])
      monthly_performance_matrix.each do |(consultant_id, performance_matrix)|
        expect(consultant_id).to eq(1)
        expect(performance_matrix.keys.sort).to eq(described_class::OPEN_LEADS_BUCKETS)
        performance_matrix.each do |(_open_leads_bucket, revenue_buckets)|
          expect(revenue_buckets.keys.sort).to eq(described_class::REVENUE_BUCKETS)
          revenue_buckets.each do |_revenue_bucket, conversion_rate|
            expect(conversion_rate).to eq(0.0)
          end
        end
      end
    end

    it "returns places the consultant in the max bucket if the consultant achieved more that the max bucket" do
      expect_any_instance_of(
        Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
      ).to receive(:closed_opportunities_for).with(beginning_of_a_month, consultant_id, category_id)
                                             .and_return(
                                               {
                                                 1 => [
                                                   generate_opportunity(closed_successfully: true,
                                                                        avg_open_opportunities: 160,
                                                                        generated_revenue_so_far: 71_000)
                                                 ]
                                               }
                                             )
      monthly_performance_matrix = subject.call(beginning_of_a_month).monthly_performance_matrix

      expect(monthly_performance_matrix.keys.sort).to eq([1])
      monthly_performance_matrix.each do |(consultant_id, performance_matrix)|
        expect(consultant_id).to eq(1)
        expect(performance_matrix.keys.sort).to eq(described_class::OPEN_LEADS_BUCKETS)
        performance_matrix.each do |(_open_leads_bucket, revenue_buckets)|
          expect(revenue_buckets.keys.sort).to eq(described_class::REVENUE_BUCKETS)
          revenue_buckets.each do |_revenue_bucket, conversion_rate|
            expect(conversion_rate).to eq(1.0)
          end
        end
      end
    end
  end
end

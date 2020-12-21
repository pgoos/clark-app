# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::GenerateHistoricalMonthlyAdminPerformance do
  describe "#call", :integration do
    let(:current_year) { 2020 }
    let(:now) { DateTime.new(current_year, 4, 15, 0, 0, 0) }

    let(:open_opportunity_buckets) do
      Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::OPEN_LEADS_BUCKETS
    end

    let(:revenue_buckets) do
      Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::REVENUE_BUCKETS
    end

    let!(:empty_performance_matrix) do
      open_opportunity_buckets.each_with_object({}) do |row_bucket, result|
        result[row_bucket.to_s] = {}
        revenue_buckets.each do |col_bucket|
          result[row_bucket.to_s][col_bucket.to_s] = nil
        end
      end
    end

    let!(:admin) { create(:admin, :sales_consultant) }
    let!(:category) { create(:category, :high_margin)}
    let(:default_version) { "default_version" }
    let(:remember_window_size) { Faker::Number.between(2, 3) }

    before do
      Timecop.freeze(now)
      allow(Settings.aoa).to receive(:current_version).and_return(default_version)
      allow(Settings.aoa.versions.default_version).to receive(:fixed_start_date).and_return("2019-12-01")
      allow(Settings.aoa.versions.default_version).to receive(:window_size).and_return(remember_window_size)
    end

    after do
      Timecop.return
      allow(Settings.aoa).to receive(:current_version).and_call_original
      allow(Settings.aoa.versions.default_version).to receive(:fixed_start_date).and_call_original
      allow(Settings.aoa.versions.default_version).to receive(:window_size).and_call_original
    end

    def check_data_completion(records)
      number_of_records = now.month - current_calculation_date.month + 1
      expect(records.count).to eq(number_of_records)
    end

    def check_data_correctness(records)
      ((current_calculation_date.month)..(now.month)).to_a.each_with_index do |month, idx|
        record = records[idx]
        date = Date.new(current_year, month, 1)
        expect(record.consultant_id).to eq(admin.id)
        expect(record.open_opportunities).to eq(0)
        expect(record.open_opportunities_category_counts).to eq({})
        expect(record.revenue).to eq(0)
        expect(record.performance_level).to eq({})
        expect(record.calculation_date.to_date).to eq(date.to_date)
        expect(record.performance_matrix).to eq(empty_performance_matrix)
      end
    end

    context "no monthly admin performance record is found" do
      let(:current_calculation_date) { now.beginning_of_year }

      it "generates data from 1th January of 2020 with nils in performance_matrix conversion_rate" do
        subject.call

        records = MonthlyAdminPerformance.where(consultant_id: admin.id).order(:calculation_date)
        check_data_completion(records)
        check_data_correctness(records)
      end

      it "triggered the PopulateMonthlyAdminPerformance interactor 5 times (4 months + current date)" do
        expect_any_instance_of(described_class)
          .to receive(:populate_monthly_admin_performance_for).exactly(5).times

        subject.call
      end
    end

    context "monthly admin performance is not updated since 2 months back" do
      let(:current_calculation_date) { now - 2.months }
      let!(:outdated_monthly_admin_performance) do
        create(:monthly_admin_performance,
               consultant_id: admin.id,
               revenue: 0,
               open_opportunities: 0,
               performance_matrix: empty_performance_matrix,
               open_opportunities_category_counts: {},
               calculation_date:  current_calculation_date.beginning_of_month)
      end

      it "generates data for last 2 months with nils in performance_matrix conversion_rate" do
        subject.call

        records = MonthlyAdminPerformance.where(consultant_id: admin.id).order(:calculation_date)
        check_data_completion(records)
        check_data_correctness(records)
      end

      it "triggered the PopulateMonthlyAdminPerformance interactor 3 times (2 months + current date)" do
        expect_any_instance_of(described_class)
          .to receive(:populate_monthly_admin_performance_for).exactly(3).times

        subject.call
      end
    end

    context "monthly admin performance is generated everyday" do
      let(:current_calculation_date) { now - 1.day }
      let!(:outdated_monthly_admin_performance) do
        create(:monthly_admin_performance,
               consultant_id: admin.id,
               revenue: 0,
               open_opportunities: 0,
               performance_matrix: empty_performance_matrix,
               open_opportunities_category_counts: {},
               calculation_date:  current_calculation_date.beginning_of_month)
      end

      it "does not generate a new records" do
        subject.call

        records = MonthlyAdminPerformance.where(consultant_id: admin.id).order(:calculation_date)
        check_data_completion(records)
        check_data_correctness(records)
      end

      it "triggered the PopulateMonthlyAdminPerformance interactor 1 time (current date only)" do
        expect_any_instance_of(described_class)
          .to receive(:populate_monthly_admin_performance_for).exactly(1).time

        subject.call
      end
    end

    context "generation fail for consultant" do
      let!(:other_consultant) { create(:admin, :sales_consultant) }
      let(:current_calculation_date) { now - 1.month }

      let!(:outdated_monthly_admin_performances) do
        [
          create(
            :monthly_admin_performance,
            consultant_id: other_consultant.id,
            revenue: 0,
            open_opportunities: 0,
            performance_matrix: empty_performance_matrix,
            open_opportunities_category_counts: {},
            calculation_date:  current_calculation_date.beginning_of_month
          ),
          create(
            :monthly_admin_performance,
            consultant_id: admin.id,
            revenue: 0,
            open_opportunities: 0,
            performance_matrix: empty_performance_matrix,
            open_opportunities_category_counts: {},
            calculation_date:  current_calculation_date.beginning_of_month
          )
        ]
      end

      before do
        allow(subject).to receive(:populate_monthly_admin_performance_for).with(
          anything, other_consultant.id
        ).and_raise(StandardError)

        allow(subject).to receive(:populate_monthly_admin_performance_for).with(
          anything, admin.id
        ).and_call_original
      end

      it "generate monthly_admin_performance for other consultants and removes it for failing consultant" do
        expect(Raven).to receive(:capture_message).once
        expect(Rails.logger)
          .to receive(:error)
          .with("Performance matrix calculation failed for consultant '#{other_consultant.id}':")
          .once
          .and_call_original
        expect(Rails.logger)
          .to receive(:error)
          .with(an_instance_of(StandardError))
          .once
          .and_call_original
        expect(Rails.logger)
          .to receive(:error)
          .with(an_instance_of(String))
          .once
          .and_call_original

        subject.call

        expect(MonthlyAdminPerformance.find_by(consultant_id: other_consultant.id)).to eq nil
        expect(MonthlyAdminPerformance.where(consultant_id: admin.id).count).to eq 2
      end
    end
  end
end

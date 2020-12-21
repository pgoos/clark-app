# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::PopulateMonthlyAdminPerformance, :integration do
  let(:open_opportunity_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::OPEN_LEADS_BUCKETS
  end
  let(:revenue_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::REVENUE_BUCKETS
  end
  let(:admin_id_with_data) { create(:admin).id }
  let(:admin_id_with_no_data) { create(:admin).id }
  let(:beginning_of_a_month) { DateTime.new(2010, 4, 1, 0, 0, 0) }
  let(:after_beginning_of_a_month) { beginning_of_a_month + Faker::Number.between(from: 1, to: 20).days }
  let(:consultant_ids) { [admin_id_with_data, admin_id_with_no_data] }
  let(:category_ids) { [] }
  let(:performance_level) { { admin_id_with_no_data => {}, admin_id_with_data => { ident1: "a", ident2: "c" } } }
  let(:successful_opportunity_data) {
    {
      closed_successfully: true,
      revenue: Faker::Number.between(from: 1000.0, to: 3000.0),
      avg_open_opportunities: 2.5,
      generated_revenue_so_far: 3000
    }
  }
  let(:failed_opportunity_data) {
    {
      closed_successfully: false,
      revenue: Faker::Number.between(from: 1000.0, to: 3000.0),
      avg_open_opportunities: 2.5,
      generated_revenue_so_far: 3000
    }
  }
  let(:closed_opportunities_response) {
    { admin_id_with_data => [successful_opportunity_data, failed_opportunity_data], admin_id_with_no_data => nil }
  }
  let(:monthly_performance_response) {
    {
      admin_id_with_data => {
        id: Faker::Number.between(from: 5, to: 10),
        performance_matrix: fake_performance_matrix(0.5)
      },
      admin_id_with_no_data => nil
    }
  }
  let(:open_opportunities_response) {
    {
      admin_id_with_data => { open_opportunities_category_counts: { ident1: 4, ident2: 6 }, open_opportunities: 10 },
      admin_id_with_no_data => nil
    }
  }
  let(:default_version) { "default_version" }
  let(:remember_window_size) { Faker::Number.between(2, 3) }

  before do
    allow(Settings.aoa).to receive(:current_version).and_return(default_version)
    allow(Settings.aoa.versions.default_version).to receive(:window_size).and_return(remember_window_size)
  end

  after do
    allow(Settings.aoa).to receive(:current_version).and_call_original
    allow(Settings.aoa.versions.default_version).to receive(:window_size).and_call_original
  end

  def fake_performance_matrix(conversion_rate)
    open_opportunity_buckets.each_with_object({}) do |row_bucket, result|
      result[row_bucket] = {}
      revenue_buckets.each do |col_bucket|
        result[row_bucket][col_bucket] = conversion_rate
      end
    end
  end

  def mock_repositories_responses(date)
    closed_opportunity_call_for_revenue = instance_double(
      Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
    ).tap do |instance|
      expect(instance).to receive(:closed_opportunities_for).once.with(date, consultant_ids, category_ids)
                                                            .and_return(closed_opportunities_response)
    end

    closed_opportunity_call_for_matrix = instance_double(
      Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
    ).tap do |instance|
      expect(instance).to receive(:closed_opportunities_for).at_most(1).with(date - 1.day, consultant_ids, category_ids)
                                                            .and_return(closed_opportunities_response)
    end

    closed_opportunity_call_for_forget_matrix = instance_double(
      Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository
    ).tap do |instance|
      expect(instance).to receive(:closed_opportunities_for)
        .at_most(1)
        .with(date - 1.day - remember_window_size.months, consultant_ids, category_ids)
        .and_return(closed_opportunities_response)
    end

    expect(Sales::Constituents::Opportunity::Repositories::ClosedOpportunitiesRepository)
      .to receive(:new).at_most(3).and_return(closed_opportunity_call_for_revenue,
                                              closed_opportunity_call_for_matrix,
                                              closed_opportunity_call_for_forget_matrix)

    expect_any_instance_of(
      Sales::Constituents::Opportunity::Repositories::OpenOpportunitiesCountRepository
    ).to receive(:open_opportunities_count_for).with(consultant_ids, category_ids)
                                               .and_return(open_opportunities_response)
    expect_any_instance_of(
      Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository
    ).to receive(:load_latest_performance_matrix_for).with(default_version, consultant_ids)
                                                     .and_return(monthly_performance_response)

    allow_any_instance_of(
      Sales::Constituents::Opportunity::Repositories::AdminPerformanceClassificationsRepository
    ).to receive(:performance_classifications).and_call_original

    allow_any_instance_of(
      Sales::Constituents::Opportunity::Repositories::AdminPerformanceClassificationsRepository
    ).to receive(:performance_classifications).with(
      [admin_id_with_data, admin_id_with_no_data]
    ).and_return(
      admin_id_with_data    => { performance_level: { ident1: "a", ident2: "c" } },
      admin_id_with_no_data => { performance_level: {} }
    )

    mock_save_call(date, admin_id_with_data)
    mock_save_call(date, admin_id_with_no_data)
  end

  def mock_save_call(date, admin_id)
    params = expected_save_params(date, admin_id)
    expect_any_instance_of(Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository)
      .to receive(:save!).with(params, id(date, admin_id)).and_return(params.merge({ id: id(date, admin_id) }))
  end

  def expected_save_params(date, admin_id)
    admin_open_opportunities = open_opportunities_response[admin_id]
    admin_monthly_performance = monthly_performance_response[admin_id]
    revenue = admin_id == admin_id_with_data ? successful_opportunity_data[:revenue] : 0.0
    performance_matrix = if admin_id == admin_id_with_data
                           admin_monthly_performance.try(:[], :performance_matrix).presence || {}
                         else
                           date == beginning_of_a_month ? fake_performance_matrix(nil) : {}
                         end

    {
      consultant_id: admin_id,
      revenue: revenue,
      open_opportunities_category_counts: admin_open_opportunities.try(:[], :open_opportunities_category_counts) || {},
      open_opportunities: admin_open_opportunities.try(:[], :open_opportunities) || 0,
      performance_level: performance_level[admin_id],
      calculation_date: date.beginning_of_month,
      performance_matrix: performance_matrix,
      algo_version: default_version
    }
  end

  def test_results(results, date)
    expect(results).to be_an_instance_of(Array)
    expect(results).to match_array [
      expected_result_for_admin_with_no_data(date),
      expected_result_for_admin_with_data(date)
    ]
  end

  def expected_result_for_admin_with_data(date)
    admin_open_opportunities = open_opportunities_response[admin_id_with_data] || {}
    admin_monthly_performance = monthly_performance_response[admin_id_with_data] || {}
    {
      consultant_id: admin_id_with_data,
      id: id(date, admin_id_with_data),
      revenue: successful_opportunity_data[:revenue],
      open_opportunities_category_counts: admin_open_opportunities[:open_opportunities_category_counts],
      open_opportunities: admin_open_opportunities[:open_opportunities],
      performance_level: performance_level[admin_id_with_data],
      calculation_date: beginning_of_a_month,
      performance_matrix: admin_monthly_performance[:performance_matrix],
      algo_version: default_version
    }
  end

  def expected_result_for_admin_with_no_data(date)
    {
      consultant_id: admin_id_with_no_data,
      id: nil,
      revenue: 0.0,
      open_opportunities_category_counts: {},
      open_opportunities: 0,
      performance_level: performance_level[admin_id_with_no_data],
      calculation_date: beginning_of_a_month,
      performance_matrix: date == beginning_of_a_month ? fake_performance_matrix(nil) : {},
      algo_version: default_version
    }
  end

  def id(date, admin_id)
    is_beginning_of_month = date == beginning_of_a_month
    is_beginning_of_month ? nil : monthly_performance_response[admin_id].try(:[], :id)
  end

  describe "#call" do
    context "creates a new record" do
      it "when passed date is the beginning of a month" do
        mock_repositories_responses(beginning_of_a_month)
        results = subject.call(beginning_of_a_month, consultant_ids, category_ids).monthly_admin_performances
        test_results(results, beginning_of_a_month)
      end

      it "when no previous record for the resolved admin in the running month" do
        mock_repositories_responses(after_beginning_of_a_month)
        results = subject.call(after_beginning_of_a_month, consultant_ids, category_ids).monthly_admin_performances
        test_results(results, after_beginning_of_a_month)
      end
    end

    context "updates an existing record" do
      it "when passed date after the beginning of month and new data found for an existing admin record" do
        mock_repositories_responses(after_beginning_of_a_month)
        results = subject.call(after_beginning_of_a_month, consultant_ids, category_ids).monthly_admin_performances
        test_results(results, after_beginning_of_a_month)
      end
    end
  end
end

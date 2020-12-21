# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::CalculateRevenue do
  subject {
    described_class.new(
      closed_opportunities_repo: closed_opportunities_repo,
      monthly_admin_performances_repo: monthly_admin_performances_repo,
      sales_admins_repo: sales_admins_repo,
      aoa_categories_repo: aoa_categories_repo
    )
  }

  let(:default_version) { "default_version" }
  let(:remember_window_size) { Faker::Number.between(2, 3) }
  let!(:admin1) { double :admin, access_flags: %w[sales_consultation], id: 1 }
  let!(:admin2) { double :admin, access_flags: %w[], id: 2 }
  let!(:closed_opportunities_repo) { double :repo, closed_opportunities_for: nil }
  let!(:monthly_admin_performances_repo) { double :repo, load_latest_performance_matrix_for: nil, save!: nil }
  let!(:sales_admins_repo) { double :repo, sales_consultation_permitted?: false }
  let!(:aoa_categories_repo) { double :repo, select_categories_used_in_aoa: nil }
  let(:open_opportunity_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::OPEN_LEADS_BUCKETS
  end
  let(:revenue_buckets) do
    Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix::REVENUE_BUCKETS
  end
  let(:admin_id_with_data) { admin1.id }
  let(:admin_id_with_no_data) { admin2.id }
  let(:category_ids) { [] }
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

  def fake_performance_matrix(conversion_rate)
    open_opportunity_buckets.each_with_object({}) do |row_bucket, result|
      result[row_bucket] = {}
      revenue_buckets.each do |col_bucket|
        result[row_bucket][col_bucket] = conversion_rate
      end
    end
  end

  before do
    allow(Settings.aoa).to receive(:current_version).and_return(default_version)
    allow(Settings.aoa.versions.default_version).to receive(:window_size).and_return(remember_window_size)
    allow(sales_admins_repo).to receive(:sales_consultation_permitted?).with(admin1.id).and_return(true)
    allow(sales_admins_repo).to receive(:sales_consultation_permitted?).with(admin2.id).and_return(false)
    allow(closed_opportunities_repo).to receive(:closed_opportunities_for).and_return(closed_opportunities_response)
    allow(monthly_admin_performances_repo)
      .to receive(:load_latest_performance_matrix_for).and_return(monthly_performance_response)
    allow(monthly_admin_performances_repo).to receive(:save!)
    allow(aoa_categories_repo).to receive(:select_categories_used_in_aoa).and_return(category_ids)
  end

  after do
    allow(Settings.aoa).to receive(:current_version).and_call_original
    allow(Settings.aoa.versions.default_version).to receive(:window_size).and_call_original
  end

  describe "#call" do
    context "saves with consultant having sales-consultation access" do
      it "validates the consultant" do
        expect(sales_admins_repo).to receive(:sales_consultation_permitted?).with(admin1.id)

        subject.call(admin1.id)
      end

      it "gathers the required information" do
        expect(closed_opportunities_repo)
          .to receive(:closed_opportunities_for).with(Date.current, admin1.id, category_ids)
        expect(monthly_admin_performances_repo)
          .to receive(:load_latest_performance_matrix_for).with(default_version, admin1.id)

        subject.call(admin1.id)
      end

      it "saves the results" do
        expect(monthly_admin_performances_repo).to receive(:save!)

        subject.call(admin1.id)
      end
    end

    context "saves with consultant not having sales-consultation access" do
      it "validates the consultant" do
        expect(sales_admins_repo).to receive(:sales_consultation_permitted?).with(admin2.id)

        subject.call(admin2.id)
      end

      it "does NOT gather any information" do
        expect(closed_opportunities_repo).not_to receive(:closed_opportunities_for)
        expect(monthly_admin_performances_repo).not_to receive(:load_latest_performance_matrix_for)

        subject.call(admin2.id)
      end

      it "does NOT save" do
        expect(monthly_admin_performances_repo).not_to receive(:save!)

        subject.call(admin2.id)
      end
    end
  end
end

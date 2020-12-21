# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::CalculatePerformanceMatrix do
  let!(:open_opportunity_buckets) { [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140] }
  let!(:revenue_buckets) { [3000, 9000, 17_000, 23_000, 27_000, 33_000, 47_000, 53_000, 70_000] }
  let(:beginning_of_a_month) { DateTime.new(2010, 4, 1, 0, 0, 0) }
  let(:last_conversion_rate) { Faker::Number.between(from: 0.1, to: 0.9) }
  let(:new_conversion_rate) { Faker::Number.between(from: 0.1, to: 0.9) }
  let(:last_performance_matrix_sample) { fake_performance_matrix(last_conversion_rate) }
  let(:new_performance_matrix_sample) { fake_performance_matrix(new_conversion_rate) }
  let(:new_consultant_matrix) { fake_performance_matrix(nil) }
  let(:consultant_id_has_data) { 1 }
  let(:consultant_id_has_no_data) { 2 }
  let(:module_to_mock) { Sales::Constituents::Opportunity::Interactors::CalculateMonthlyPerformanceMatrix }
  let(:remember_window_size) { Faker::Number.between(from: 7, to: 10) }
  let(:number_of_months) { Faker::Number.between(from: 1, to: 5) }
  let(:default_version) { "default_version" }

  before do
    allow(Settings.aoa).to receive(:current_version).and_return(default_version)
    allow(Settings.aoa.versions.default_version).to receive(:window_size).and_return(remember_window_size)
  end

  def fake_performance_matrix(conversion_rate)
    open_opportunity_buckets.each_with_object({}) do |row_bucket, result|
      result[row_bucket] = {}
      revenue_buckets.each do |col_bucket|
        result[row_bucket][col_bucket] = conversion_rate
      end
    end
  end

  def new_averaged_matrix(count, new_matrix)
    old = last_performance_matrix_sample
    forget = new_matrix.clone # because mocking the call will return the same result all the time
    new_matrix.each_with_object({}) do |(row_bucket, col_buckets), results|
      results[row_bucket] = {}
      col_buckets.each do |col_bucket, conversion_rate|
        new_conversion_rate = old[row_bucket][col_bucket].to_f +
          (conversion_rate.to_f - forget[row_bucket][col_bucket].to_f) / count
        results[row_bucket][col_bucket] = new_conversion_rate
      end
    end
  end

  context "when no consultant ids passed" do
    it "returns current performance matrix for any consultant has data" do
      allow(module_to_mock).to receive_message_chain(:new, :call).and_return(
        object_double("result", monthly_performance_matrix: { consultant_id_has_data => new_performance_matrix_sample })
      )
      results = subject.call(beginning_of_a_month).performance_matrix
      expect(results.keys).to eq([consultant_id_has_data])
      expect(results[consultant_id_has_data][:performance_matrix]).to eq(new_performance_matrix_sample)
    end
  end

  context "when a consultant id passed has data" do
    it "returns the monthly performance matrix if no past averages passed" do
      allow(module_to_mock).to receive_message_chain(:new, :call).and_return(
        object_double("result", monthly_performance_matrix: { consultant_id_has_data => new_performance_matrix_sample })
      )
      last_averages_data = { consultant_id_has_data => nil }
      results = subject.call(beginning_of_a_month, last_averages_data).performance_matrix
      expect(results.keys).to eq([consultant_id_has_data])
      expect(results[consultant_id_has_data][:performance_matrix]).to eq(new_performance_matrix_sample)
    end

    it "returns the new average performance matrix if past averages passed" do
      allow(module_to_mock).to receive_message_chain(:new, :call).and_return(
        object_double("result", monthly_performance_matrix: { consultant_id_has_data => new_performance_matrix_sample })
      )
      last_averages_data = {
        consultant_id_has_data => {
          last_performance_matrix: last_performance_matrix_sample,
          count: number_of_months
        }
      }
      results = subject.call(beginning_of_a_month, last_averages_data).performance_matrix
      expect(results.keys).to eq([consultant_id_has_data])
      expect(results[consultant_id_has_data][:performance_matrix])
        .to eq(new_averaged_matrix(number_of_months, new_performance_matrix_sample))
    end
  end

  context "when a consultant id passed has no data" do
    it "returns the new monthly performance matrix if no past averages passed" do
      allow(module_to_mock).to receive_message_chain(:new, :call).and_return(
        object_double("result", monthly_performance_matrix: { consultant_id_has_no_data => new_consultant_matrix })
      )
      last_averages_data = { consultant_id_has_no_data => nil }
      results = subject.call(beginning_of_a_month, last_averages_data).performance_matrix
      expect(results.keys).to eq([consultant_id_has_no_data])
      expect(results[consultant_id_has_no_data][:performance_matrix]).to eq(new_consultant_matrix)
    end

    it "returns the new average performance matrix if past averages passed" do
      allow(module_to_mock).to receive_message_chain(:new, :call).and_return(
        object_double("result", monthly_performance_matrix: { consultant_id_has_no_data => new_consultant_matrix })
      )
      last_averages_data = {
        consultant_id_has_no_data => {
          last_performance_matrix: last_performance_matrix_sample,
          count: number_of_months
        }
      }
      results = subject.call(beginning_of_a_month, last_averages_data).performance_matrix
      expect(results.keys).to eq([consultant_id_has_no_data])
      expect(results[consultant_id_has_no_data][:performance_matrix])
        .to eq(new_averaged_matrix(number_of_months, new_consultant_matrix))
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe MonthlyAdminPerformance, type: :model do
  describe ".with_category_performance_level" do
    let!(:performance_level) { { abc: "a", cde: "b" } }
    let!(:monthly_performance) { create(:monthly_admin_performance, performance_level: performance_level) }

    def check_performance_level_value(query_level)
      result = MonthlyAdminPerformance.with_category_performance_level(query_level).first
      expect(result).to eq(monthly_performance)
      performance_level = monthly_performance.performance_level[query_level.to_s]
      expect(result.performance_level).to eq(performance_level)
    end

    it "returns proper monthly admin performances" do
      check_performance_level_value(:abc)
      check_performance_level_value("cde")
      check_performance_level_value("non-existing")
    end

    it "returns the full hash if nil passed" do
      result = MonthlyAdminPerformance.with_category_performance_level(nil).first
      expect(result).to eq(monthly_performance)
      expect(result.performance_level.symbolize_keys!).to eq(performance_level)
    end
  end

  describe ".with_version" do
    let(:algo_version) { "new_algo_version" }
    let!(:monthly_performance) { create(:monthly_admin_performance, algo_version: algo_version) }
    let!(:monthly_performance_on_another_version) { create(:monthly_admin_performance) }

    it "returns the correct monthly admin performances" do
      result_ids = MonthlyAdminPerformance.with_version(algo_version).map(&:id)
      expect(result_ids).to eq([monthly_performance.id])
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Domain::Admins::MonthlyAdminPerformanceObservers::AdminPerformanceLevelObserver do
  let(:admin) { create(:admin, role: create(:role)) }
  let(:category) { create(:category) }

  let(:performance_classification) do
    create :admin_performance_classification, admin: admin, category: category, level: "a"
  end

  describe "#performance_level_changed" do
    it "triggers interactor with proper arguments" do
      expect(::Sales).to receive(:update_consultant_performance_level)
        .with(
          consultant_id: performance_classification.admin_id,
          category_ident: category.ident,
          performance_level: performance_classification.level
        )

      described_class.performance_level_changed(
        performance_classification
      )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Domain::Admins::MonthlyAdminPerformanceObservers::RevenueObserver, :integration do
  let(:mandate) { create(:mandate, user: user) }
  let(:opportunity) { create(:opportunity, mandate: mandate) }
  let(:user) { create(:user) }

  describe "#calculate_revenue" do
    it "receives event with proper arguments" do
      opportunity.state = "offer_phase"
      opportunity.cancel
      expect(
        Domain::Admins::MonthlyAdminPerformanceObservers::RevenueObserver
      ).to receive(:calculate_revenue).with(opportunity.admin_id)
      described_class.calculate_revenue(opportunity.admin_id)
    end
  end
end

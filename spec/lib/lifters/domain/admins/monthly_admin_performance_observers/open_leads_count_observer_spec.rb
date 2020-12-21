# frozen_string_literal: true

require "rails_helper"

describe Domain::Admins::MonthlyAdminPerformanceObservers::OpenLeadsCountObserver do
  let(:mandate) { create(:mandate, user: user) }
  let(:opportunity) { create(:opportunity, mandate: mandate) }
  let(:user) { create(:user) }

  describe "#open_leads_count_changed" do
    it "receives event with proper arguments" do
      opportunity.state = "offer_phase"
      opportunity.cancel
      expect(
        Domain::Admins::MonthlyAdminPerformanceObservers::OpenLeadsCountObserver
      ).to receive(:open_leads_count_changed).with(opportunity.admin_id)
      described_class.open_leads_count_changed(opportunity.admin_id)
    end
  end
end

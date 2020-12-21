# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::PlanRepository, :integration do
  describe "#all" do
    let!(:plan1) { create(:plan, plan_state_begin: Date.new(2018, 1)) }
    let!(:plan2) { create(:plan, plan_state_begin: Date.new(2019, 1)) }
    let!(:plan3) { create(:plan, plan_state_begin: nil) }
    let!(:plan4) { create(:plan, plan_state_begin: "") }

    it "returns the correct plans" do
      plans = subject.all
      expect(plans).to match_array([plan1, plan2])
    end
  end
end

# frozen_string_literal: true

require "rails_helper"
load "db/migrate/20181002094544_dismiss_equity_recommendations.rb"

RSpec.describe DismissEquityRecommendations, :integration do
  describe "#data" do
    let(:recommendations) { Recommendation.where(category: category) }

    before do
      create_list(:recommendation, 3, category: category, dismissed: false)

      described_class.new.data
    end

    context "when equity-related" do
      let(:category) { create(:category, :equity) }

      it { expect(recommendations).to all(be_dismissed) }
    end

    context "when not equity-related" do
      let(:category) { create(:category, :state) }

      it { expect(recommendations.pluck(:dismissed)).to all(be false) }
    end
  end
end

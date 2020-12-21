# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake recommendations:equity_cleanup", integration: true, type: :task do
  let!(:equity_category) { create(:category, :equity) }

  describe "equity_cleanup" do
    context "when equity category" do
      let!(:recommendations) { create_list(:recommendation, 2, category: equity_category) }

      before { task.invoke }

      it do
        expect(Recommendation.where(id: recommendations.pluck(:id))).not_to exist
      end
    end

    context "when not equity" do
      let(:other_category) { create(:bu_category) }
      let!(:recommendations) { create_list(:recommendation, 2, category: other_category, dismissed: true) }

      it do
        expect(Recommendation.where(id: recommendations.pluck(:id))).to exist
      end
    end
  end
end

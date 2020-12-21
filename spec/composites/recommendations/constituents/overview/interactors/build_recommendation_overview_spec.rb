# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Recommendations::Constituents::Overview::Interactors::BuildRecommendationOverview do
  context "when customer_id is passed in" do
    it "calls recommendation_repo.build_recommendations method" do
      expect_any_instance_of(
        ::Recommendations::Constituents::Overview::Repositories::RecommendationRepository
      ).to receive(:build_recommendations).with(12).and_return([])

      interactor = described_class.new.call(12)
      expect(interactor).to be_success
      expect(interactor.recommendations).to eq([])
    end
  end

  describe ".number_one_recommendation" do
    let(:mandate) { create(:mandate) }
    let(:interactor) { described_class.new.call(mandate.id) }
    let(:category) do
      create(:category, ident: "730c2a87", has_category_page: true, life_aspect: :things)
    end

    let!(:recommendation) do
      create(:recommendation, category: category, mandate: mandate)
    end

    it "returns the number 1 recommendation" do
      recommendation_entity = interactor.number_one_recommendation
      expect(recommendation_entity.id).to eq(recommendation.id)
      expect(recommendation_entity).to be_an_instance_of(
        ::Recommendations::Constituents::Overview::Entities::Recommendation
      )
    end

    context "without category page" do
      let(:category) { create(:category, has_category_page: false) }

      it "returns nil" do
        expect(interactor.number_one_recommendation).to be_nil
      end
    end

    context "retirement category" do
      let(:category) do
        create(:category, life_aspect: :retirement)
      end

      it "returns nil" do
        expect(interactor.number_one_recommendation).to be_nil
      end
    end

    context "when recommendation is in covered state" do
      let!(:product) do
        create(:product, :customer_provided, category: category, mandate: mandate)
      end

      it "returns nil" do
        expect(interactor.number_one_recommendation).to be_nil
      end
    end

    context "with multiple recommendations in recommended and other state" do
      let!(:opportunity) do
        create(:opportunity, :created, category: category, mandate: mandate)
      end

      let(:category2) do
        create(:category, ident: "7afbebb8", has_category_page: true, life_aspect: :health)
      end

      let!(:recommendation2) do
        create(:recommendation, category: category2, mandate: mandate)
      end

      it "returns the recommended recommendation" do
        expect(interactor.recommendations.count).to eq(2)
        expect(interactor.recommendations.pluck(:state)).to match_array(%w[recommended requested])
        expect(interactor.number_one_recommendation.id).to eq(recommendation2.id)
        expect(interactor.number_one_recommendation.state).to eq('recommended')
      end
    end
  end
end

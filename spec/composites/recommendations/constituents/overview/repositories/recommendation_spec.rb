# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Recommendations::Constituents::Overview::Repositories::RecommendationRepository, :integration do
  describe ".build_recommendations" do
    let(:customer) { create(:customer) }

    context "when recommendation for kfz-Absicherung(Umbrella) exists" do
      let(:regular_category) { create(:category, category_type: :regular) }
      let!(:umbrella_category) do
        create(
          :category_kfz,
          category_type: :umbrella,
          included_category_ids: [regular_category.id]
        )
      end
      let!(:offered_recommendation) do
        create(:recommendation, category: umbrella_category, mandate_id: customer.id)
      end

      context "when an offer exists for a combo category which shares a regular category with parent umbrella category" do
        let!(:combo_category) do
          create(
            :category,
            category_type: :combo,
            included_category_ids: [regular_category.id]
          )
        end
        let(:offer) { create(:active_offer, mandate_id: customer.id) }
        let!(:opportunity) do
          create(
            :opportunity,
            mandate_id: customer.id,
            category: combo_category,
            offer: offer,
            state: :offer_phase
          )
        end

        it "show recommendation state as offered with offer" do
          recommendation_entity =
            described_class.new.build_recommendations(customer.id).first

          expect(recommendation_entity.state).to eq("offered")
          expect(recommendation_entity.offer).not_to be_nil
        end
      end
    end

    context "when recommendation with offer exists" do
      let(:category) do
        create(:category, :kapitallebensversicherung)
      end
      let(:offer) { create(:active_offer, mandate_id: customer.id) }
      let!(:opportunity) do
        create(:opportunity, mandate_id: customer.id, category: category, offer: offer, state: :offer_phase)
      end
      let!(:offered_recommendation) do
        create(:recommendation, category: category, mandate_id: customer.id)
      end

      it "returns recommendation attributes" do
        recommendation_entity = described_class.new.build_recommendations(customer.id).first

        expect(recommendation_entity.id).to eq(offered_recommendation.id)
        expect(recommendation_entity.state).to eq("offered")

        expect(recommendation_entity).to be_an_instance_of(
          ::Recommendations::Constituents::Overview::Entities::Recommendation
        )
        expect(recommendation_entity.category).to be_an_instance_of(
          ::Recommendations::Constituents::Overview::Entities::Category
        )
        expect(recommendation_entity.offer).to be_an_instance_of(
          ::Recommendations::Constituents::Overview::Entities::Offer
        )
      end
    end

    describe "when multiple recommendations with different priority exists" do
      let(:low_priority_category_recommended) { create(:category, priority: 1) }
      let(:high_priority_category_recommended) { create(:category, priority: 2) }
      let(:low_prio_category_requested) { create(:category, priority: 3) }
      let(:high_prio_category_requested) { create(:category, priority: 4) }
      let(:low_prio_category_offered) { create(:category, priority: 1) }
      let(:high_prio_category_offered) { create(:category, priority: 2) }
      let(:low_priority_category_covered) { create(:category, priority: 0) }
      let(:high_priority_category_covered) { create(:category, priority: 2) }
      let(:offer) { create(:offer, state: :active, mandate_id: customer.id) }
      let!(:low_prio_opportunity) do
        create(:opportunity, mandate_id: customer.id, category: low_prio_category_requested)
      end
      let!(:high_prio_opportunity) do
        create(:opportunity, mandate_id: customer.id, category: high_prio_category_requested)
      end
      let!(:low_prio_opportunity_for_offered) do
        create(
          :opportunity,
          state: :offer_phase,
          offer: offer,
          mandate_id: customer.id,
          category: low_prio_category_offered
        )
      end
      let!(:high_prio_opportunity_for_offered) do
        create(
          :opportunity,
          state: :offer_phase,
          offer: offer,
          mandate_id: customer.id,
          category: high_prio_category_offered
        )
      end
      let(:low_priority_plan) { create(:plan, category_id: low_priority_category_covered.id) }
      let!(:low_priority_product) do
        create(:product, mandate_id: customer.id, plan: low_priority_plan)
      end
      let(:high_priority_plan) { create(:plan, category_id: high_priority_category_covered.id) }
      let!(:high_priority_product) do
        create(:product, mandate_id: customer.id, plan: high_priority_plan)
      end
      let!(:recommended_low_prio) do
        create(
          :recommendation,
          mandate_id: customer.id,
          category: low_priority_category_recommended
        )
      end
      let!(:recommended_high_prio) do
        create(
          :recommendation,
          mandate_id: customer.id,
          category: high_priority_category_recommended
        )
      end
      let!(:requested_low_prio) do
        create(:recommendation, mandate_id: customer.id, category: low_prio_category_requested)
      end
      let!(:requested_high_prio) do
        create(:recommendation, mandate_id: customer.id, category: high_prio_category_requested)
      end
      let!(:offered_low_prio) do
        create(:recommendation, mandate_id: customer.id, category: low_prio_category_offered)
      end
      let!(:offered_high_prio) do
        create(:recommendation, mandate_id: customer.id, category: high_prio_category_offered)
      end
      let!(:covered_low_prio) do
        create(:recommendation, mandate_id: customer.id, category: low_priority_category_covered)
      end
      let!(:covered_high_prio) do
        create(:recommendation, mandate_id: customer.id, category: high_priority_category_covered)
      end

      it "sort by priority and state" do
        recommendation_ids = described_class.new.build_recommendations(customer.id).map(&:id)
        expected_order = [
          covered_high_prio.id,
          covered_low_prio.id,
          offered_high_prio.id,
          offered_low_prio.id,
          requested_high_prio.id,
          requested_low_prio.id,
          recommended_high_prio.id,
          recommended_low_prio.id
        ]

        expect(recommendation_ids).to eq(expected_order)
      end
    end
  end
end

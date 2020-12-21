# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::RecommendationState do
  let(:mandate) { create(:mandate) }
  let(:questionnaire) { create(:questionnaire) }
  let(:category) { create(:category, questionnaire: questionnaire, ident: category_ident) }
  let(:recommendation) { create(:recommendation, mandate: mandate, category: category) }
  let(:user_situation) { Domain::Situations::UserSituation.new(mandate) }
  let(:subject) { described_class.new(recommendation, user_situation) }

  let(:category_ident) { "any" }

  context "#customer_finished_questionnaire?" do
    it "returns true when the customer has a finished Questionnaire::Response \
        and there is an opportunity present" do
      create(:questionnaire_response, questionnaire: questionnaire,
                                      mandate:       mandate,
                                      state:         "completed")
      create(:opportunity, mandate: mandate, category: category, state: "created")
      expect(subject.customer_finished_questionnaire?).to eq(true)
    end

    it "returns false when the customer has not created any responses" do
      expect(subject.customer_finished_questionnaire?).to eq(false)
    end

    it "returns false when no questionnaire is attached to the category" do
      category.update_attributes(questionnaire: nil)
      expect(subject.customer_finished_questionnaire?).to eq(false)
    end

    it "returns false when the last associated opportunity is lost" do
      create(:opportunity, mandate: mandate, category: category, state: "lost")
      expect(subject.customer_finished_questionnaire?).to eq(false)
    end
  end

  context "customer_did_not_finish_questionnaire?" do
    it "returns true when customer has unfinished responses and no finished responses" do
      create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate)
      expect(subject).to receive(:customer_finished_questionnaire?).and_return(false)
      expect(subject.customer_did_not_finish_questionnaire?).to eq(true)
    end
    it "returns false when customer has unfinished responses but also finished responses" do
      create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate)
      expect(subject).to receive(:customer_finished_questionnaire?).and_return(true)
      expect(subject.customer_did_not_finish_questionnaire?).to eq(false)
    end
    it "returns false when no questionnaire is attached to the category" do
      category.update_attributes(questionnaire: nil)
      expect(subject.customer_did_not_finish_questionnaire?).to eq(false)
    end
  end

  context "#offer" do
    it "returns the offer if mandate has an opportunity in offer phase on the category" do
      opportunity = create(:opportunity_with_offer, mandate:  mandate,
                                                                category: category)
      expect(subject.offer).to eq(opportunity.offer)
    end

    it "returns nil if mandate has an opportunity on the category but not in offer phase" do
      create(:opportunity, mandate: mandate, category: category)
      expect(subject.offer).to be_nil
    end

    it "returns nil if mandate has no opportunity on the category" do
      expect(subject.offer).to be_nil
    end
  end

  describe "#owned?" do
    context "when mandate has an inquiry of the category" do
      let(:inquiry_category) do
        create(
          :inquiry_category,
          category: category
        )
      end

      let!(:inquiry) do
        create(
          :inquiry,
          mandate: mandate,
          state: ::Inquiry::OPEN_INQUIRY_STATES.first,
          inquiry_categories: [inquiry_category]
        )
      end

      it "returns true" do
        expect(subject).to be_owned
      end
    end

    context "when relevant categories contain owned products" do
      let(:plan) { create(:plan) }

      let!(:product) do
        create(
          :product,
          mandate: mandate,
          category: category,
          plan: plan,
          state: ::Product::STATES_OF_ACTIVE_PRODUCTS.first
        )
      end

      before do
        allow_any_instance_of(Domain::MasterData::Categories).to(
          receive(:relevant_ids_for_showing_if_something_is_owned)
            .and_return([category.id])
        )
      end

      after do
        allow_any_instance_of(Domain::MasterData::Categories).to(
          receive(:relevant_ids_for_showing_if_something_is_owned)
            .and_call_original
        )
      end

      it "returns true" do
        expect(subject).to be_owned
      end
    end

    context "when condition doesn't met" do
      it "returns false" do
        expect(subject).not_to be_owned
      end
    end
  end

  describe "#retirement_item?" do
    context "when category is equity (1fc11bd4)" do
      let(:category_ident) { "1fc11bd4" }

      it "returns true" do
        expect(subject).to be_retirement_item
      end
    end

    context "when category is GRV / public pension insurance (84a5fba0)" do
      let(:category_ident) { "84a5fba0" }

      it "returns true" do
        expect(subject).to be_retirement_item
      end
    end

    context "when category doesn't match allowed" do
      let(:category_ident) { "not_allowed" }

      it "returns false" do
        expect(subject).not_to be_retirement_item
      end
    end
  end

  describe "#offer?" do
    let(:category_ident) { "any" }

    let(:opportunity) do
      create(
        :opportunity,
        mandate: mandate,
        category: category,
        state: offer_state
      )
    end

    let!(:offer) do
      create(
        :offer,
        mandate: mandate,
        opportunity: opportunity
      )
    end

    context "when there is a relevant offer" do
      let(:offer_state) { "offer_phase" }

      it "returns true" do
        expect(subject).to be_offer
      end
    end

    context "when there is no relevant offer" do
      let(:offer_state) { "completed" }

      it "returns false" do
        expect(subject).not_to be_offer
      end
    end
  end

  describe "#owned_products" do
    let(:category_ident) { "any" }

    let(:plan) { create(:plan) }

    context "when there is a relevant product" do
      let!(:product) do
        create(
          :product,
          mandate: mandate,
          category: category,
          plan: plan,
          state: ::Product::STATES_OF_ACTIVE_PRODUCTS.first
        )
      end

      it "returns product id" do
        expect(subject.owned_products).to match([product.category.id])
      end
    end

    context "when there is no relevant product" do
      it "returns an empty array" do
        expect(subject.owned_products).to match([])
      end
    end
  end
end

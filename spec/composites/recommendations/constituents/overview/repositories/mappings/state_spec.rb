# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommendations::Constituents::Overview::Repositories::Mappings::State, :integration do
  describe ".entity_value" do
    let(:mapper) { described_class }
    let(:category) { create(:category, :kapitallebensversicherung) }
    let(:kfz_category) { create(:category_kfz) }
    let(:another_mandate) { create(:mandate) }
    let(:recommendation) { create(:recommendation, category: category) }
    let(:combo_category) { create(:category, :combo) }
    let(:recommendation_combo) { create(:recommendation, category: combo_category) }
    let(:umbrella_category) { create(:category, :umbrella) }
    let(:recommendation_umbrella) { create(:recommendation, category: umbrella_category) }

    context "logic for 'covered'" do
      context "when valid contract exists" do
        let!(:product) do
          create(
            :product,
            category: category,
            mandate: recommendation.mandate,
            state: :customer_provided,
            contract_ended_at: Time.current.tomorrow
          )
        end

        it "returns 'covered'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::COVERED)
        end
      end

      context "when contract's end_date is null" do
        let!(:product) do
          create(
            :product,
            category: category,
            mandate: recommendation.mandate,
            state: :customer_provided,
            contract_ended_at: nil
          )
        end

        it "state is 'covered'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::COVERED)
        end
      end

      context "when contract exists with 'terminated' state" do
        let!(:product) do
          create(
            :product,
            category: category,
            mandate: recommendation.mandate,
            state: :terminated
          )
        end

        it "state is not 'covered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::COVERED)
        end
      end

      context "when valid contract exists for another category" do
        let!(:product) do
          create(
            :product,
            category: kfz_category,
            mandate: recommendation.mandate,
            contract_ended_at: Time.current.tomorrow
          )
        end

        it "state is not 'covered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::COVERED)
        end
      end

      context "when inquiry exists" do
        let(:inquiry) { create(:inquiry, mandate: recommendation.mandate) }
        let!(:inquiry_category) do
          create(:inquiry_category, inquiry: inquiry, category: recommendation.category)
        end

        it "returns 'covered'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::COVERED)
        end
      end

      context "when inquiry exists for another category" do
        let(:inquiry) { create(:inquiry, mandate: recommendation.mandate) }
        let!(:inquiry_category) do
          create(:inquiry_category, inquiry: inquiry, category: kfz_category)
        end

        it "state is not 'covered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::COVERED)
        end
      end

      context "when valid inquiry exists for another mandate" do
        let(:inquiry) { create(:inquiry, mandate: another_mandate) }
        let!(:inquiry_category) do
          create(:inquiry_category, inquiry: inquiry, category: category)
        end

        it "state is not 'covered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::COVERED)
        end
      end
    end

    context "logic for 'offered'" do
      context "when offer exists" do
        let(:offer) { create(:offer, state: :active) }
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :offer_phase,
            offer: offer
          )
        end

        it "returns 'offered'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::OFFERED)
        end
      end

      context "when recommendation exist for a umbrella category" do
        context "when offer exist for one of included category" do
          let(:offer) { create(:offer, state: :active) }
          let!(:opportunity) do
            create(
              :opportunity,
              mandate: recommendation_umbrella.mandate,
              category: umbrella_category.included_categories.first,
              state: :offer_phase,
              offer: offer
            )
          end

          it "returns 'offered'" do
            expect(mapper.entity_value(recommendation_umbrella.id)).to eq(mapper::OFFERED)
          end
        end
      end

      context "when offer is expired" do
        let(:offer) { create(:offer, state: :expired) }
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :offer_phase,
            offer: offer
          )
        end

        it "does not return 'offered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::OFFERED)
        end
      end

      context "when offer exists for another mandate" do
        let(:offer) { create(:offer, state: :active) }
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: another_mandate,
            category: recommendation.category,
            state: :offer_phase,
            offer: offer
          )
        end

        it "does not return 'offered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::OFFERED)
        end
      end

      context "when offer is send through email(No offer in system)" do
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :offer_phase,
            offer_id: nil
          )
        end

        it "return state as 'offered'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::OFFERED)
        end
      end
    end

    context "logic for 'requested'" do
      context "when opportunity in 'lost' state exists" do
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :lost
          )
        end

        it "does not return 'requested'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::REQUESTED)
        end
      end

      context "when valid opportunity for another customer exists" do
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: another_mandate,
            category: recommendation.category,
            state: :created
          )
        end

        it "does not return 'requested'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::REQUESTED)
        end
      end

      context "when opportunity in 'created' state exists" do
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :created
          )
        end

        it "returns 'requested'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::REQUESTED)
        end
      end

      context "when opportunity is in 'offer_phase' and Offer does not exists" do
        let!(:opportunity) do
          create(
            :opportunity,
            mandate: recommendation.mandate,
            category: recommendation.category,
            state: :initiation_phase
          )
        end

        it "returns 'requested'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::REQUESTED)
        end
      end
    end

    context "logic for 'recommended'" do
      context "when product/inquiry/offer/opportunity does not exist" do
        it "returns 'recommended'" do
          expect(mapper.entity_value(recommendation.id)).to eq(mapper::RECOMMENDED)
        end
      end

      context "when expired product exists" do
        let!(:product) do
          create(
            :product,
            category: category,
            mandate: recommendation.mandate,
            state: :customer_provided,
            contract_ended_at: Time.current.yesterday
          )
        end

        it "does not return 'covered'" do
          expect(mapper.entity_value(recommendation.id)).not_to eq(mapper::COVERED)
        end
      end
    end
  end
end

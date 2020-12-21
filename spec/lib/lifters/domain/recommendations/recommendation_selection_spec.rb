# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::RecommendationSelection do
  let(:mandate) { create(:mandate) }
  let(:mandate_not_accpeted) { create(:mandate, :created) }
  let(:questionnaire) { create(:questionnaire) }
  let(:category) { create(:category, questionnaire: questionnaire, priority: 10, name: "AB", life_aspect: "health") }
  let(:category_2) { create(:category, questionnaire: questionnaire, priority: 4, life_aspect: "health") }
  let(:category_3) { create(:category, questionnaire: questionnaire, priority: 3, life_aspect: "health") }
  let(:category_4) { create(:category, questionnaire: questionnaire, priority: 2, life_aspect: "things") }
  let(:category_5) { create(:category, questionnaire: questionnaire, priority: 10, name: "AA", life_aspect: "things") }
  let(:category_retirement) { create(:category, questionnaire: questionnaire, priority: 100, name: "AAA", life_aspect: "retirement") }
  let(:recommendation) { create(:recommendation, mandate: mandate, category: category) }


  describe ".number_one_recommendation" do
    context "recommendations are filtered" do
      context "mandate is accepted" do
        let(:subject) { described_class.new(mandate) }

        it "returns nil if not done demandcheck" do
          expect(subject.number_one_recommendation).to be_nil
        end

        context "mandate has done the demandcheck" do
          before do
            recommendation
            allow(mandate).to receive(:done_with_demandcheck?).and_return(true)
          end

          it "returns the only recommendation with the mandate" do
            expect(subject.number_one_recommendation).to eq(recommendation)
          end

          context "when product state is terminated" do
            let!(:plan) { create(:plan, category: category) }
            let!(:product) { create(:product, :terminated, mandate: mandate, plan: plan, contract_ended_at: end_time) }

            context "contract not ended" do
              let(:end_time) { 2.days.from_now }

              it "doesn't show the recommendation" do
                expect(subject.number_one_recommendation).to be_nil
              end
            end

            context "contract ended" do
              let(:end_time) { 2.days.ago }

              it "show the recommendation" do
                expect(subject.number_one_recommendation).to eq(recommendation)
              end
            end
          end

          context "mandate has multiple recommendations" do
            let!(:recommendation_2) { create(:recommendation, mandate: mandate, category: category_2) }
            let!(:recommendation_3) { create(:recommendation, mandate: mandate, category: category_3) }
            let!(:recommendation_4) { create(:recommendation, mandate: mandate, category: category_4) }

            it "should correctly return the highest priority recommendation" do
              expect(subject.number_one_recommendation).to eq(recommendation)
            end
          end

          context "mandate has couple of recommendations with the same priority" do
            let!(:recommendation_5) { create(:recommendation, mandate: mandate, category: category_5) }

            it "should correctly sort by the name if priority is the same" do
              expect(subject.number_one_recommendation).to eq(recommendation_5)
            end
          end

          context "dont return the recommendations with active products" do
            let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category)) }

            it "doesnt show the recommendation if it has the product active" do
              expect(subject.number_one_recommendation).to be_nil
            end

            context "has the recommendation thats low in prio but has no active products" do
              let!(:recommendation_2) { create(:recommendation, mandate: mandate, category: category_2) }

              it "returns the recommendation that has no active product but lower prio" do
                expect(subject.number_one_recommendation).to eq(recommendation_2)
              end
            end
          end

          context "dont return the recommendations with active inquiry" do
            let!(:inquiry) { create(:inquiry, mandate: mandate, state: :pending) }
            let!(:inquiry_category) { create(:inquiry_category, category: category, inquiry: inquiry) }

            it "doesn't show the recommendation if it has active product" do
              expect(subject.number_one_recommendation).to be_nil
            end

            context "has the recommendation thats low in prio but has no active inquiry" do
              let!(:recommendation_2) { create(:recommendation, mandate: mandate, category: category_2) }

              it "returns the recommendation that has no active inquiry but lower prio" do
                expect(subject.number_one_recommendation).to eq(recommendation_2)
              end
            end
          end

          context "it ignores the recommendations with life aspect retirement" do
            let!(:recommendation_retirement) { create(:recommendation, mandate: mandate, category: category_retirement) }

            it "ignores recommendation with retirement life aspect even it has a higher priority" do
              expect(subject.number_one_recommendation).to eq(recommendation)
            end
          end

          context "combo category product and inquiry" do
            let(:hrv_category) { create(:category, ident: 'e251294f', name: 'Hausratversicherung', priority: 100) }
            let(:combo_category) { create(:combo_category, included_categories: [hrv_category,category ]) }

            before do
              combo_category
              hrv_category
              create(:recommendation, mandate: mandate, category: hrv_category)
            end

            context "has products of combo categories which includes the category in recommendation" do

              before do
                create(:product, mandate: mandate, plan: create(:plan, category: combo_category))
              end

              it "should have no number one recommendation" do
                expect(subject.number_one_recommendation).to be_nil
              end
            end

            context "has inquiries of combo categories which includes the category in recommendation" do
              let!(:inquiry) { create(:inquiry, mandate: mandate, state: :pending) }

              before do
                create(:inquiry_category, category: combo_category, inquiry: inquiry)
              end

              it "should have no number one recommendation" do
                expect(subject.number_one_recommendation).to be_nil
              end
            end
          end
        end
      end
    end
  end

  describe ".recommendations_sorted_by_priority" do
    let(:mandate) { create(:mandate) }

    context "when customer does not have any recommendations" do
      it "returns empty array" do
        expect(described_class.new(mandate).recommendations_sorted_by_priority).to be_empty
      end
    end

    context "when customer has multiple recommendation of different priorities" do
      let!(:recommendation_1) do
        create(:recommendation, mandate: mandate, category: create(:category_kfz, priority: 1))
      end
      let!(:recommendation_2) do
        create(:recommendation, mandate: mandate, category: create(:category_hr, priority: 2))
      end
      let!(:recommendation_3) do
        create(:recommendation, mandate: mandate, category: create(:category_gkv, priority: 3))
      end
      let!(:recommendation_5) do
        create(:recommendation, mandate: mandate, category: create(:category_retirement, priority: 100))
      end

      it "returns recommendations sorted in descending priority order without retirement recommendation" do
        expect(
          described_class.new(mandate).recommendations_sorted_by_priority.pluck(:id)
        ).to eq(
          [recommendation_3.id, recommendation_2.id, recommendation_1.id]
        )
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe OutboundChannels::Reminders::NumberOneRecommendation, type: :integration do
  describe "#customers" do
    let!(:category) { create(:category_phv, life_aspect: "health") }
    let!(:questionnaire) { create(:bedarfscheck_questionnaire, category: category) }

    context "when customer does demandcheck yesterday without creating product" do
      let!(:mandate_wo_product) { create(:mandate, :accepted) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: mandate_wo_product,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 1.day.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: mandate_wo_product)
      end

      it "return No.1 recommendation" do
        expect(described_class.new.recommendations).to include(recommendation)
      end
    end

    context "when customer does demandcheck yesterday and creates product for No.1 recommended category" do
      let!(:mandate_with_product) { create(:mandate, :accepted) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: mandate_with_product,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 1.day.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: mandate_with_product)
      end
      let!(:product) { create(:product, mandate: mandate_with_product, category: category) }

      it "does not return No.1 recommendation" do
        expect(described_class.new.recommendations).not_to include(recommendation)
      end
    end

    context "when customer does demandcheck yesterday and creates inquiry for No.1 recommended category" do
      let!(:mandate_with_enquiry) { create(:mandate, :accepted) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: mandate_with_enquiry,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 1.day.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: mandate_with_enquiry)
      end
      let!(:inquiry) { create(:inquiry, mandate: mandate_with_enquiry) }
      let!(:inquiry_category) { create(:inquiry_category, category: category, inquiry: inquiry) }

      it "does not return No.1 recommendation" do
        expect(described_class.new.recommendations).not_to include(recommendation)
      end
    end

    context "when revoked mandate does demandcheck yesterday and creates inquiry for No.1 recommended category" do
      let!(:revoked_mandate) { create(:mandate, :revoked) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: revoked_mandate,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 1.day.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: revoked_mandate)
      end

      it "does not return No.1 recommendation" do
        expect(described_class.new.recommendations).not_to include(recommendation)
      end
    end

    context "when called with custom timeframe" do
      let!(:revoked_mandate) { create(:mandate, :accepted) }
      let!(:questionnaire_response) {
        create(
          :questionnaire_response,
          mandate: revoked_mandate,
          questionnaire: questionnaire,
          state: :analyzed,
          finished_at: 5.days.ago
        )
      }
      let!(:recommendation) do
        create(:recommendation, category: category, mandate: revoked_mandate)
      end

      context "when recommendation exists in given timeframe" do
        it "return return No.1 recommendation" do
          start_time = 5.days.ago.beginning_of_day
          end_time = 5.days.ago.end_of_day

          expect(
            described_class.new(starts: start_time, ends: end_time).recommendations
          ).to include(recommendation)
        end
      end

      context "when given timeframe is before recommendation finished_at time" do
        it "does not return recommendation" do
          start_time = 10.days.ago.beginning_of_day
          end_time = 6.days.ago.end_of_day

          expect(
            described_class.new(starts: start_time, ends: end_time).recommendations
          ).to be_empty
        end
      end

      context "when given timeframe is after recommendation finished_at time" do
        it "does not return recommendation" do
          start_time = 4.days.ago.beginning_of_day
          end_time = 1.days.ago.end_of_day

          expect(
            described_class.new(starts: start_time, ends: end_time).recommendations
          ).to be_empty
        end
      end
    end
  end
end

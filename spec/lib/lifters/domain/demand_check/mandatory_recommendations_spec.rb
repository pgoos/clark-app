# frozen_string_literal: true

require "rails_helper"

describe Domain::DemandCheck::MandatoryRecommendations do
  include RecommendationsSpecHelper
  let(:mandate) { create(:mandate) }
  let(:bedarfcheck_questionnaire) { create(:bedarfscheck_questionnaire) }
  let!(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate, questionnaire: bedarfcheck_questionnaire)
  end

  describe "#apply_rules" do
    before(:all) do
      create_or_get_category(described_class::KFZ_IDENT)
      create_or_get_category(described_class::GKV_IDENT)
      create_or_get_category(described_class::PHV_IDENT)
      create_or_get_category(described_class::PRIVATE_RETIREMENT_IDENT)
      create_or_get_category(described_class::PKZ_IDENT)
      create_or_get_category(described_class::PKV_IDENT)
      create_or_get_category(described_class::PET_OWNERS_LIABILITY_IDENT)
      create_or_get_category(described_class::PUBLIC_RETIREMENT_IDENT)
    end

    after(:all) do
      destroy_category(described_class::KFZ_IDENT)
      destroy_category(described_class::GKV_IDENT)
      destroy_category(described_class::PHV_IDENT)
      destroy_category(described_class::PRIVATE_RETIREMENT_IDENT)
      destroy_category(described_class::PKZ_IDENT)
      destroy_category(described_class::PKV_IDENT)
      destroy_category(described_class::PET_OWNERS_LIABILITY_IDENT)
      destroy_category(described_class::PUBLIC_RETIREMENT_IDENT)
    end
    context "vehicle insurance" do
      it "it marks KFZ as place holder if user answer demand_vehicle with Auto" do
        create_question_with_answer("demand_vehicle", "Auto", questionnaire_response)
        recommendation = create_category_recommendation(described_class::KFZ_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "it marks KFZ as place holder if user answer demand_vehicle with Wohnwagen" do
        create_question_with_answer("demand_vehicle", "Wohnwagen", questionnaire_response)
        recommendation = create_category_recommendation(described_class::KFZ_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "it marks KFZ as place holder if user answer demand_vehicle with Anhanger" do
        create_question_with_answer("demand_vehicle", "Anhanger", questionnaire_response)
        recommendation = create_category_recommendation(described_class::KFZ_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it_behaves_like(
        "a placeholder for category", "Motorrad", described_class::KFZ_IDENT
      )

      it "it does not marks KFZ as place holder if user answer demand_vehicle with Nien" do
        create_question_with_answer("demand_vehicle", "Nien", questionnaire_response)
        recommendation = create_category_recommendation(described_class::KFZ_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it_behaves_like(
        "a mandatory recommendator for", "Auto", described_class::KFZ_IDENT
      )
    end

    context "pets liability insurance" do
      it "it marks pets owners liability insurance as place holder if user answer demand_pets with Hund" do
        create_question_with_answer("demand_pets", "Hund", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "it marks pets owners liability insurance as place holder if user answer demand_pets with Pferd" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark POL insurance recommendation as mandatory if the user has an open inquiry of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_active_inquiry_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks POL insurance recommendation as mandatory if the user has an inactive inquiry of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_inactive_inquiry_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark POL insurance recommendation as mandatory if the user has an active product of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_product_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks POL insurance recommendation as mandatory if the user has an inactive prodcut of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_inactive_product_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark POL insurance recommendation as mandatory if the user has an active opportunity of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_active_opportunity_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks POL insurance recommendation as mandatory if the user has an inactive opportunity of POL" do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PET_OWNERS_LIABILITY_IDENT)
        create_inactive_opportunity_of_category(described_class::PET_OWNERS_LIABILITY_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end
    end

    context "GKV" do
      it "it marks GKV insurance as place holder if user answer demand_health_insurance_type with gesetzlich krankenversichert" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an open inquiry of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_active_inquiry_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an open inquiry of PKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_active_inquiry_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks GKV insurance recommendation as mandatory if the user has an inactive inquiry of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_inactive_inquiry_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an active product of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_product_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an active product of PKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_product_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks GKV insurance recommendation as mandatory if the user has an inactive prodcut of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_inactive_product_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an active opportunity of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_active_opportunity_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark GKV insurance recommendation as mandatory if the user has an active opportunity of PKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_active_opportunity_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks GKV insurance recommendation as mandatory if the user has an inactive opportunity of GKV" do
        create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::GKV_IDENT)
        create_inactive_opportunity_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end
    end

    context "PKV" do
      it "it marks PKV insurance as place holder if user answer demand_health_insurance_type with privat krankenversichert" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "it does not mark PKV insurance as place holder if user answer demand_job with Arbeitssuchend" do
        create_question_with_answer("demand_job", "privat Arbeitssuchend", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an open inquiry of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_active_inquiry_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an open inquiry of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_active_inquiry_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks PKV insurance recommendation as mandatory if the user has an inactive inquiry of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_inactive_inquiry_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an active product of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_product_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an active product of GKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_product_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks PKV insurance recommendation as mandatory if the user has an inactive prodcut of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_inactive_product_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an active opportunity of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_active_opportunity_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "does not mark PKV insurance recommendation as mandatory if the user has an active opportunity of GKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_active_opportunity_of_category(described_class::GKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

      it "marks PKV insurance recommendation as mandatory if the user has an inactive opportunity of PKV" do
        create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
        recommendation = create_category_recommendation(described_class::PKV_IDENT)
        create_inactive_opportunity_of_category(described_class::PKV_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(true)
      end
    end

    context "public retirement insurance" do
      let(:jobs_getting_placeholder) do
        [
          "bis zu 57.600",
          "uber 57.600",
          "Selbststandig",
          "Freiberufler",
          "Beamter",
          "Auszubildender",
          "Student",
          "Arbeitssuchend"
        ]
      end

      it "does not mark public retirement insurance recommendation as mandatory if the user has an open inquiry of that category" do
        create_question_with_answer("demand_job", jobs_getting_placeholder.first, questionnaire_response)
        recommendation = create_category_recommendation(described_class::PUBLIC_RETIREMENT_IDENT)
        create_active_inquiry_of_category(described_class::PUBLIC_RETIREMENT_IDENT, mandate)
        described_class.new(questionnaire_response).apply_rules([recommendation])
        expect(recommendation.reload.is_mandatory).to eq(false)
      end

    end
  end
end

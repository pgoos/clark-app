# frozen_string_literal: true

RSpec.shared_examples "a mandatory recommendator for" do |answer, category_ident|
  include RecommendationsSpecHelper

  describe "category #{category_ident}" do
    it "does not mark insurance recommendation as mandatory if the user has an open inquiry" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_active_inquiry_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(false)
    end

    it "marks insurance recommendation as mandatory if the user has an inactive inquiry" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_inactive_inquiry_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(true)
    end

    it "does not mark insurance recommendation as mandatory if the user has an active product" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_product_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(false)
    end

    it "marks insurance recommendation as mandatory if the user has an inactive product" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_inactive_product_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(true)
    end

    it "does not mark insurance recommendation as mandatory if the user has an active opportunity" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_active_opportunity_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(false)
    end

    it "marks insurance recommendation as mandatory if the user has an inactive opportunity" do
      create_question_with_answer("demand_vehicle", answer, questionnaire_response)
      recommendation = create_category_recommendation(category_ident)
      create_inactive_opportunity_of_category(category_ident, mandate)
      described_class.new(questionnaire_response).apply_rules([recommendation])
      expect(recommendation.reload.is_mandatory).to eq(true)
    end
  end
end

RSpec.shared_examples "a placeholder for category" do |answer, category_ident|
  include RecommendationsSpecHelper

  it "marks category #{category_ident} as place holder if user answer demand_vehicle with #{answer}" do
    create_question_with_answer("demand_vehicle", answer, questionnaire_response)
    recommendation = create_category_recommendation(category_ident)
    described_class.new(questionnaire_response).apply_rules([recommendation])
    expect(recommendation.reload.is_mandatory).to eq(true)
  end
end

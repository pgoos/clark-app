# frozen_string_literal: true

module RecommendationsSpecHelper
  def create_or_get_category(category_ident)
    category = Category.find_by(ident: category_ident)
    if category.nil?
      category = create(:category, ident: category_ident)
    end
    category
  end

  def destroy_category(category_ident)
    category = Category.find_by(ident: category_ident)
    category.destroy! if category.present?
  end

  def create_question_with_answer(question_ident, answer, questionnaire_response)
    question = create(:questionnaire_custom_question, question_identifier: question_ident)
    create(:questionnaire_answer, question: question, questionnaire_response: questionnaire_response, answer: {text: answer})
  end

  def create_product_of_category(category_ident, mandate)
    plan = create(:plan, category: create_or_get_category(category_ident), subcompany: create(:subcompany))
    create(:product, plan: plan, mandate: mandate, state: :under_management)
  end

  def create_inactive_product_of_category(category_ident, mandate)
    plan = create(:plan, category: create_or_get_category(category_ident), subcompany: create(:subcompany))
    create(:product, plan: plan, mandate: mandate, state: :canceled)
  end

  def create_active_inquiry_of_category(category_ident, mandate)
    inquiry = create(:inquiry, mandate: mandate, state: :pending)
    create(
      :inquiry_category,
      category: create_or_get_category(category_ident),
      inquiry:  inquiry
    )
    inquiry
  end

  def create_inactive_inquiry_of_category(category_ident, mandate)
    inquiry = create(:inquiry, mandate: mandate, state: :canceled)
    create(:inquiry_category, category: create_or_get_category(category_ident), inquiry: inquiry)
    inquiry
  end

  def create_active_opportunity_of_category(category_ident, mandate)
    create(:opportunity, category: create_or_get_category(category_ident), mandate: mandate, state: :initiation_phase)
  end

  def create_inactive_opportunity_of_category(category_ident, mandate)
    create(:opportunity, category: create_or_get_category(category_ident), mandate: mandate, state: :lost)
  end

  def recommendations_contain_category?(recommendations, category_ident)
    recommendations.joins(:category).pluck("categories.ident").member?(category_ident)
  end

  def recommendation_dismissed?(recommendations, category_ident)
    recommendations.find { |recommendation| recommendation.category_id == Category.find_by(ident: category_ident).id }
  end

  def recommendation_for(recommendations, category_ident)
    query = {"categories.ident" => category_ident}
    mandate.recommendations
           .joins(:category)
           .where(query)
           .first
  end

  def create_category_recommendation(category_ident)
    create(:recommendation, category: create_or_get_category(category_ident), mandate: mandate)
  end

  def create_active_offer(category_ident)
    opportunity = create_active_opportunity_of_category(category_ident, mandate)
    create(:offer, opportunity: opportunity, mandate: mandate, state: :active)
  end
end

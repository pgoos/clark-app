# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manager::TodolistHelper, type: :helper do
  let!(:mandate)       { create(:mandate) }
  let!(:questionnaire) { create(:questionnaire) }
  let!(:category)      { create(:category, questionnaire: questionnaire) }

  before do
    # Create the `current_mandate` method on the helper so that we can mock it
    def helper.current_mandate; end
    allow(helper).to receive(:current_mandate).and_return(mandate)
  end

  context "customer_finished_questionnaire?" do
    let(:subject) { helper.customer_finished_questionnaire?(category) }

    it "returns true when the customer has a finished Questionnaire::Response" do
      create(:questionnaire_response, questionnaire: questionnaire, mandate: mandate,
                                                  state: "completed", created_at: 1.year.ago)
      create(:opportunity, mandate: mandate, category: category, state: "created")

      expect(subject).to eq(true)
    end

    it "returns false when the customer has not created any responses" do
      expect(subject).to eq(false)
    end

    it "returns false when no questionnaire is attached to the category" do
      category.update_attributes(questionnaire: nil)
      expect(subject).to eq(false)
    end

    it "returns false when the last associated opportunity is lost" do
      create(:opportunity, mandate: mandate, category: category, state: "lost")
      expect(subject).to eq(false)
    end
  end

  context "customer_did_not_finish_questionnaire?" do
    let(:subject) { helper.customer_did_not_finish_questionnaire?(category) }

    it "returns true when customer has unfinished responses and no finished responses" do
      create(:questionnaire_response, questionnaire: questionnaire,
                                                  mandate: mandate, state: "created",
                                                  created_at: 12.minutes.ago)

      expect(helper).to receive(:customer_finished_questionnaire?).and_return(false)
      expect(subject).to eq(true)
    end

    it "returns false when customer has unfinished responses but also finished responses" do
      create(:questionnaire_response, questionnaire: questionnaire,
                                                  mandate: mandate,
                                                  state: "created", created_at: 12.minutes.ago)

      expect(helper).to receive(:customer_finished_questionnaire?).and_return(true)
      expect(subject).to eq(false)
    end

    it "returns false when no questionnaire is attached to the category" do
      category.update_attributes(questionnaire: nil)
      expect(subject).to eq(false)
    end
  end
end

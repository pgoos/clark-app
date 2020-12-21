# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::CustomerWantsOffer do
  let(:matrix_class) { Domain::OfferGeneration::Matrix }
  let(:offer_builder_class) { matrix_class::OfferBuilder }

  it { expect(described_class).to respond_to(:call) }

  context "when execution is permitted" do
    before do
      allow(offer_builder_class).to receive(:creation_permitted?).with(any_args).and_return(true)
      create(:admin, email: RoboAdvisor::ADVICE_ADMIN_EMAILS.sample, role: create(:role))
    end

    context "when the questionnaire response is finished", :integration do
      it "should create an offer, if a rule is matched" do
        # setup a category with coverage features to be used in the offer
        cov1 = "coverage_ident1"
        cov2 = "coverage_ident2"
        cov3 = "coverage_ident3"
        coverage_features = [
          build(:coverage_feature, identifier: cov1),
          build(:coverage_feature, identifier: cov2),
          build(:coverage_feature, identifier: cov3)
        ]
        category = create(:category, coverage_features: coverage_features)

        # prepare the questionnaire
        question1 = create(:multiple_choice_question)
        question2 = create(:multiple_choice_question_multiple)

        questionnaire = create(:questionnaire, questions: [question1, question2], category: category)

        # prepare the response
        response = create(:questionnaire_response, questionnaire: questionnaire, state: "in_progress")
        opportunity = create(:opportunity, mandate: response.mandate, source: response, category: category, admin: nil)

        answer_text1 = "response text value 1"
        response.answers.create(
          question: question1,
          answer: ValueTypes::Text.new(answer_text1),
          question_text: question1.question_text
        )

        multiple_selection = %w[multiple1 multiple2]
        answer_text2 = multiple_selection.join(", ")
        response.answers.create(
          question: question2,
          answer: ValueTypes::Text.new(answer_text2),
          question_text: question2.question_text
        )

        # setup the automation:
        automation = create(
          :offer_automation,
          :active,
          questionnaire: questionnaire,
          note_to_customer: "sample text",
          default_coverage_feature_idents: [cov1, cov2, cov3]
        )

        rule = create(
          :active_offer_rule,
          offer_automation: automation,
          category: category,
          answer_values: {
            question1.question_identifier => answer_text1,
            question2.question_identifier => multiple_selection
          }
        )

        rule.update!(
          plan_option_types: {
            rule.plan_idents[0] => :top_cover,
            rule.plan_idents[1] => :top_cover_and_price,
            rule.plan_idents[2] => :top_price
          }
        )

        # trigger the execution
        expect { described_class.(response) }.to change { rule.offers.count }.by(1)
        opportunities = rule.offers.map(&:opportunity)
        expect(opportunities.count).to eq(1)
        opportunity = opportunities.first
        expect(opportunity).to be_is_automated
        expect(opportunity.admin).to be_present
        offer_options = opportunity.offer.offer_options
        offer_options.each do |offer_option|
          expect(rule.plan_option_types[offer_option.plan_ident]).to eq offer_option.option_type
        end
      end
    end
  end

  context "when execution is not permitted" do
    let(:opportunity) { n_instance_double(Opportunity, "opportunity1") }
    let(:response) { n_instance_double(Questionnaire::Response, "response", opportunity: opportunity) }

    before do
      allow(offer_builder_class).to receive(:creation_permitted?).with(opportunity: opportunity).and_return(false)
    end

    it "should not try to process a rule" do
      expect(matrix_class).not_to receive(:with_matching_rule)
      described_class.(response)
    end
  end

  context "when opportunity already assigned to the consultant" do
    let(:opportunity) { build_stubbed(:opportunity, state: "created", admin_id: 1) }
    let(:response) { n_instance_double(Questionnaire::Response, "response", opportunity: opportunity) }

    it "should not try to process a rule" do
      expect(matrix_class).not_to receive(:with_matching_rule)

      described_class.(response)
    end
  end

  context "questionnaire has multiple-choice question", type: :integration do
    let!(:questionnaire) { create(:questionnaire, identifier: "j9lt7V") }
    let!(:category) { create(:category) }
    let(:company) { create(:company) }
    let(:subcompany) { create(:subcompany) }
    let!(:plans) { create_list(:plan, 3, category: category, subcompany: subcompany, company: company) }
    let!(:question) do
      create(
        :questionnaire_question,
        :questionnaires => [questionnaire],
        "type"                => "Questionnaire::TypeformQuestion",
        "question_text"       =>
          "Welche Bereiche möchtest du zusätzlich zum privaten Rechtsschutz absichern?",
        "value_type"          => "Text",
        "question_identifier" => "zh2MoKeOSDFp",
        "required"            => false,
        "question_type"       => "multiple-choice",
        "metadata"            => {
          "multiple-choice" =>
            { "choices" =>
              [{ "label"   => "Verkehr",
                "value"    => "Verkehr",
                "position" => 0,
                "selected" => false },
               { "label" => "Wohnen (ohne Vermietung)",
                  "value"    => "Wohnen (ohne Vermietung)",
                  "position" => 1,
                  "selected" => false }],
              "multiple" => true }
        }
      )
    end
    let!(:response) do
      create(:questionnaire_response, :in_progress, questionnaire: questionnaire, opportunity: create(:opportunity))
    end
    let!(:offer_automation) do
      create(:offer_automation,
             "name"                            => "Rechtsschutz V3",
             "state"                           => "active",
             "questionnaire_id"                => questionnaire.id,
             "default_coverage_feature_idents" => %w[slbste322029f7dc9c15c dckng080e265c1c284489 dckng3fe9d3d50e6df33d],
             "note_to_customer"                => "Test")
    end
    let!(:offer_rule) do
      create(:offer_rule,
             "name"                => "7.3_LI_S_FL_PH_ND",
             "state"               => "active",
             "offer_automation_id" => offer_automation.id,
             "category_id"         => category.id,
             "answer_values"       => { "zh2MoKeOSDFp" => "Wohnen (ohne Vermietung)" },
             "plan_idents"         => plans.map(&:ident),
             "activated"           => false)
    end

    before do
      allow(Domain::OfferGeneration::Matrix::OfferBuilder).to receive(:creation_permitted?).with(any_args).and_return(true)
      offer_rule.update!(activated: true)

      create(:questionnaire_answer,
             questionnaire_question_id: question.id,
             answer:                    { "text" => "Wohnen (ohne Vermietung)" },
             questionnaire_response:    response,
             question_text:             "Welche Bereiche möchtest du zusätzlich zum privaten Rechtsschutz absichern?")

      response.finish
      response.save
    end

    it "creates offer" do
      expect_any_instance_of(
        Domain::OfferGeneration::Matrix::OfferBuilder
      ).to receive(:new_offer).and_return(double(:offer))
      expect(::OfferGeneration).to receive_message_chain(:offers_repository, :create_and_send)
      Domain::OfferGeneration::Matrix::CustomerWantsOffer.(response)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Extensions::At::Domain::DemandCheck::RecommendationsBuilder do
  include RecommendationsSpecHelper

  subject(:apply_rules) { builder.apply_rules }

  let(:builder) { Domain::DemandCheck::RecommendationsBuilder.new(questionnaire_response) }

  let(:mandate) { create(:mandate) }
  let(:bedarfcheck_questionnaire) { create(:bedarfscheck_questionnaire) }
  let(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate, questionnaire: bedarfcheck_questionnaire)
  end

  def additional_idents
    %w[
      08e4af50 0218c56d 5dea25ae 975ad2bd 212b78ee 1ded8a0f f2a9c2e0 8d5803cf
      35196803 c1f180cd bd03dbe5 465dc897 b371af9d 47a1b441 15f6b555
    ]
  end

  def mock_custom_builder(builder)
    custom_builder = builder.send(:custom_builder)

    allow(custom_builder).to receive(:customer_has_category?).and_call_original

    allow(custom_builder).to(
      receive(:customer_has_category?)
        .with(anything, existing_category)
        .and_return(true)
    )
  end

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    Domain::DemandCheck::RecommendationsBuilder::CATEGORY_IDENTS.each { |ident| create_or_get_category ident }
    additional_idents.each { |ident| create_or_get_category ident }
  end

  after(:all) do
    Domain::DemandCheck::RecommendationsBuilder::CATEGORY_IDENTS.each { |ident| destroy_category ident }
    additional_idents.each { |ident| destroy_category ident }
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    allow(Settings).to receive_message_chain(:demandcheck, :recommendations_builder, :custom_builder)
      .and_return("Extensions::At::Domain::DemandCheck::RecommendationsBuilder")
    class_name = "Domain::DemandCheck::RecommendationsBuilder"
    stub_const("#{class_name}::ANIMAL_HEALTH_INSURANCE", "08e4af50")
    stub_const("#{class_name}::ANIMAL_LIABILITY_INSURANCE", "0218c56d")
    stub_const("#{class_name}::BIKE_INSURANCE", "5dea25ae")
    stub_const("#{class_name}::CARAVAN_AND_RV_INSURANCE", "975ad2bd")
    stub_const("#{class_name}::CONSTRUCTION_INSURANCE", "212b78ee")
    stub_const("#{class_name}::EMPLOYER_FUNDED_PENSION_INSURANCE", "1ded8a0f")
    stub_const("#{class_name}::HOUSE_HOLD_AT_INSURANCE", "f2a9c2e0")

    stub_const("#{class_name}::HOME_HOUSE_HOLD_AT_INSURANCE", "b371af9d")
    stub_const("#{class_name}::HOME_AT_INSURANCE", "47a1b441")

    stub_const("#{class_name}::INDUSTRY_INSURANCE", "8d5803cf")
    stub_const("#{class_name}::JOB_AND_ORGANISATION_LIABILITY_INSURANCE", "35196803")
    stub_const("#{class_name}::MOFA_MOPED_INSURANCE", "c1f180cd")
    stub_const("#{class_name}::PRIVATE_SUPPLEMENTARY_HEALTH_INSURANCE", "bd03dbe5")
    stub_const("#{class_name}::YOUTH_AND_STUDENT_INSURANCE", "465dc897")
    stub_const("#{class_name}::LIABILITY_INSURANCE", "15f6b555")
  end

  shared_examples "proper insurances are recommended" do |rule, answer, insurances, excluded|
    it "recommends #{insurances.join(', ')} if #{rule} was answered '#{answer}'" do
      excluded ||= []
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      insurances.each do |insurance|
        expect(
          recommendations_contain_category?(mandate.recommendations,
                                            "Domain::DemandCheck::RecommendationsBuilder::#{insurance}".constantize)
        ).to be_truthy
      end

      excluded.each do |insurance|
        expect(
          recommendations_contain_category?(mandate.recommendations,
                                            "Domain::DemandCheck::RecommendationsBuilder::#{insurance}".constantize)
        ).to be_falsey
      end
    end
  end

  shared_examples "PKZ and disability insurances are recommended based on customer's age" do |rule, answer|
    it "does not recommend PKZ and disability insurance when customer's age is 51" do
      mandate.birthdate = 51.years.ago
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      contain_term_insurance =
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::PRIVATE_SUPPLEMENTARY_HEALTH_INSURANCE) ||
          recommendations_contain_category?(mandate.recommendations,
                                            Domain::DemandCheck::RecommendationsBuilder::DISABILITY_INSURANCE_IDENT)
      expect(contain_term_insurance).to be_falsey
    end

    it "recommends PKZ and disability insurance when customer's age is 49" do
      mandate.birthdate = 49.years.ago
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::PRIVATE_SUPPLEMENTARY_HEALTH_INSURANCE)
      ).to be_truthy
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::DISABILITY_INSURANCE_IDENT)
      ).to be_truthy
    end
  end

  shared_examples "employer funded pension is recommended based on customer's age" do |rule, answer|
    it "does not recommend employer funded pension when customer's age is 56" do
      mandate.birthdate = 56.years.ago
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::EMPLOYER_FUNDED_PENSION_INSURANCE)
      ).to be_falsey
    end

    it "recommends employer funded pension when customer's age is 54" do
      mandate.birthdate = 54.years.ago
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::EMPLOYER_FUNDED_PENSION_INSURANCE)
      ).to be_truthy
    end
  end

  shared_examples "phv insurance is not recommended" do |rule, answer|
    it "does not recommend phv insurance if #{rule} was answered '#{answer}'" do
      create_question_with_answer(rule, answer, questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::PHV_IDENT)
      ).to be_falsey
    end
  end

  shared_context "mandate has blocking insurance" do |rule, answer, ident|
    let(:category_ident) do
      "Domain::DemandCheck::RecommendationsBuilder::#{ident}".constantize
    end

    context "mandate has active offer" do
      before { create_active_offer(category_ident) }

      it_behaves_like "phv insurance is not recommended", rule, answer
    end

    context "mandate has active opportunity" do
      before do
        create_active_opportunity_of_category(category_ident, mandate)
      end

      it_behaves_like "phv insurance is not recommended", rule, answer
    end

    context "mandate has active product" do
      before do
        create_product_of_category(category_ident, mandate)
      end

      it_behaves_like "phv insurance is not recommended", rule, answer
    end

    context "mandate has open inquiry" do
      before do
        create_active_inquiry_of_category(category_ident, mandate)
      end

      it_behaves_like "phv insurance is not recommended", rule, answer
    end
  end

  shared_context "mandate has house hold" do |rule, answer|
    include_context "mandate has blocking insurance", rule, answer, "HOUSE_HOLD_AT_INSURANCE"
  end

  context "demand_livingplace" do
    it_behaves_like "proper insurances are recommended", "demand_livingplace", "In einer gemieteten Wohnung",
                    ["HOUSE_HOLD_AT_INSURANCE"]

    it_behaves_like "proper insurances are recommended", "demand_livingplace", "In meiner eigenen Wohnung",
                    ["HOUSE_HOLD_AT_INSURANCE"]

    it_behaves_like "proper insurances are recommended", "demand_livingplace", "In einem gemieteten Haus",
                    ["HOUSE_HOLD_AT_INSURANCE"]

    context "when customer" do
      let(:idents) { [] }

      before do
        idents.each do |ident|
          create_active_offer(
            "Domain::DemandCheck::RecommendationsBuilder::#{ident}".constantize
          )
        end
      end

      describe "has HOUSE_HOLD_AT_INSURANCE and no HOME_HOUSE_HOLD_AT_INSURANCE, HOME_AT_INSURANCE" do
        let(:idents) { %w[HOUSE_HOLD_AT_INSURANCE] }

        it_behaves_like "proper insurances are recommended", "demand_livingplace", "In meinem eigenen Haus",
                        %w[HOME_HOUSE_HOLD_AT_INSURANCE]
      end

      describe "has HOME_HOUSE_HOLD_AT_INSURANCE and no HOUSE_HOLD_AT_INSURANCE, HOME_AT_INSURANCE" do
        let(:idents) { %w[HOME_HOUSE_HOLD_AT_INSURANCE] }

        it_behaves_like "proper insurances are recommended", "demand_livingplace", "In meinem eigenen Haus",
                        %w[HOUSE_HOLD_AT_INSURANCE]
      end

      describe "has no HOME_HOUSE_HOLD_AT_INSURANCE, HOUSE_HOLD_AT_INSURANCE, HOME_AT_INSURANCE" do
        it_behaves_like "proper insurances are recommended", "demand_livingplace", "In meinem eigenen Haus",
                        %w[HOME_AT_INSURANCE]
      end

      describe "has HOME_HOUSE_HOLD_AT_INSURANCE and HOME_AT_INSURANCE" do
        let(:idents) { %w[HOME_HOUSE_HOLD_AT_INSURANCE HOME_AT_INSURANCE] }

        it_behaves_like "proper insurances are recommended", "demand_livingplace", "In meinem eigenen Haus",
                        %w[HOUSE_HOLD_AT_INSURANCE]
      end

      describe "has HOME_AT_INSURANCE and HOUSE_HOLD_AT_INSURANCE" do
        let(:idents) { %w[HOME_AT_INSURANCE HOUSE_HOLD_AT_INSURANCE] }

        it "recommends nothing" do
          create_question_with_answer("demand_livingplace", "In meinem eigenen Haus", questionnaire_response)
          expect { apply_rules }.not_to change(mandate.recommendations, :count)
        end
      end

      describe "has HOME_AT_INSURANCE" do
        let(:idents) { %w[HOME_AT_INSURANCE] }

        it "recommends nothing" do
          create_question_with_answer("demand_livingplace", "In meinem eigenen Haus", questionnaire_response)
          expect { apply_rules }.not_to change(mandate.recommendations, :count)
        end
      end
    end

    it_behaves_like "proper insurances are recommended", "demand_livingplace", "Andere Wohnsituation", ["PHV_IDENT"]

    include_context(
      "mandate has blocking insurance",
      "demand_livingplace",
      "Andere Wohnsituation",
      "HOUSE_HOLD_AT_INSURANCE"
    )

    include_context(
      "mandate has blocking insurance",
      "demand_livingplace",
      "Andere Wohnsituation",
      "HOME_HOUSE_HOLD_AT_INSURANCE"
    )

    include_context(
      "mandate has blocking insurance",
      "demand_livingplace",
      "Andere Wohnsituation",
      "HOME_AT_INSURANCE"
    )
  end

  context "demand_estate" do
    it_behaves_like "proper insurances are recommended", "demand_estate", "Ja", ["CONSTRUCTION_INSURANCE"]
  end

  context "demand_vehicle" do
    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Auto", ["LIABILITY_INSURANCE"]

    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Motorrad", ["MOTOR_CYCLE_INSURANCE_IDENT"]

    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Mofa oder Moped", ["MOFA_MOPED_INSURANCE"]

    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Wohnwagen oder -mobil",
                    ["CARAVAN_AND_RV_INSURANCE"]

    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Anhänger", ["TRAILER_INSURANCE_IDENT"]

    it_behaves_like "proper insurances are recommended", "demand_vehicle", "Fahrrad / E-Bike / E-Scooter",
                    %w[BIKE_INSURANCE PHV_IDENT]
    include_context "mandate has house hold", "demand_vehicle", "Fahrrad / E-Bike / E-Scooter"
  end

  context "demand_family" do
    it 'recommends nothing if demand_family was answered "Ich lebe in einer Partnerschaft" and mandate age is > 55' do
      mandate.birthdate = 56.years.ago
      create_question_with_answer("demand_family", "Ich lebe in einer Partnerschaft", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end

    it 'recommends term life  if demand_family was answered "Ich lebe in einer Partnerschaft" and age is <= 55' do
      mandate.birthdate = 54.years.ago
      create_question_with_answer("demand_family", "Ich lebe in einer Partnerschaft", questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
      ).to be_truthy
    end

    it 'recommends nothing if demand_family was answered "Ich bin verheiratet" and mandate age is > 55' do
      mandate.birthdate = 56.years.ago
      create_question_with_answer("demand_family", "Ich bin verheiratet", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end

    it 'recommends term life insurance if demand_family was answered "Ich bin verheiratet" and mandate age is <= 55' do
      mandate.birthdate = 54.years.ago
      create_question_with_answer("demand_family", "Ich bin verheiratet", questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
      ).to be_truthy
    end

    it 'recommends nothing if demand_family was answered "Ich lebe alleine"' do
      create_question_with_answer("demand_family", "Ich lebe alleine", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end
  end

  context "demand_kids" do
    it 'recommends nothing if demand_kids was answered "Nein"' do
      create_question_with_answer("demand_kids", "Nein", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end

    it 'recommends nothing if demand_kids was answered "Ja" and mandate age is > 55' do
      mandate.birthdate = 56.years.ago
      create_question_with_answer("demand_kids", "Ja", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end

    it 'recommends term life insurance if demand_kids was answered "Ja" and mandate age is <= 55' do
      mandate.birthdate = 54.years.ago
      create_question_with_answer("demand_kids", "Ja", questionnaire_response)
      apply_rules
      expect(
        recommendations_contain_category?(mandate.recommendations,
                                          Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
      ).to be_truthy
    end
  end

  context "demand_job" do
    it_behaves_like "proper insurances are recommended", "demand_job", "Angestellter oder Arbeiter",
                    %w[PRIVATE_RETIREMENT_IDENT LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT]
    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Angestellter oder Arbeiter"

    it_behaves_like "proper insurances are recommended", "demand_job", "Selbstständiger",
                    %w[PRIVATE_RETIREMENT_IDENT LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT INDUSTRY_INSURANCE]
    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Selbstständiger"
    it_behaves_like "employer funded pension is recommended based on customer's age", "demand_job",
                    "Selbstständiger"

    it_behaves_like "proper insurances are recommended", "demand_job", "Freiberufler",
                    %w[PRIVATE_RETIREMENT_IDENT LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT INDUSTRY_INSURANCE]
    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Freiberufler"
    it_behaves_like "employer funded pension is recommended based on customer's age", "demand_job",
                    "Freiberufler"

    it_behaves_like "proper insurances are recommended", "demand_job", "Beamter oder Vertragsbediensteter",
                    %w[PRIVATE_RETIREMENT_IDENT LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT
                       JOB_AND_ORGANISATION_LIABILITY_INSURANCE]
    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Beamter oder Vertragsbediensteter"

    context "when Lehrling oder Student" do
      before do
        mock_custom_builder(builder)
      end

      context "with HOUSE_HOLD_AT_INSURANCE" do
        let(:existing_category) { builder.class::HOUSE_HOLD_AT_INSURANCE }

        it_behaves_like "proper insurances are recommended", "demand_job", "Lehrling oder Student",
                        %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT],
                        %w[YOUTH_AND_STUDENT_INSURANCE PHV_IDENT]
      end

      context "with HOME_HOUSE_HOLD_AT_INSURANCE" do
        let(:existing_category) { builder.class::HOME_HOUSE_HOLD_AT_INSURANCE }

        it_behaves_like "proper insurances are recommended", "demand_job", "Lehrling oder Student",
                        %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT],
                        %w[YOUTH_AND_STUDENT_INSURANCE PHV_IDENT]
      end
    end

    it_behaves_like "proper insurances are recommended", "demand_job", "Lehrling oder Student",
                    %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT YOUTH_AND_STUDENT_INSURANCE]

    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Lehrling oder Student"

    context "when Schüler" do
      before do
        mock_custom_builder(builder)
      end

      context "with HOME_HOUSE_HOLD_AT_INSURANCE" do
        let(:existing_category) { builder.class::HOME_HOUSE_HOLD_AT_INSURANCE }

        it_behaves_like "proper insurances are recommended", "demand_job", "Schüler",
                        %w[ACCIDENT_INSURANCE_IDENT DISABILITY_INSURANCE_IDENT PHV_IDENT],
                        %w[YOUTH_AND_STUDENT_INSURANCE]
      end
    end

    it_behaves_like "proper insurances are recommended", "demand_job", "Schüler",
                    %w[ACCIDENT_INSURANCE_IDENT DISABILITY_INSURANCE_IDENT PHV_IDENT YOUTH_AND_STUDENT_INSURANCE]

    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Schüler"
    include_context "mandate has house hold", "demand_job", "Schüler"

    it_behaves_like "proper insurances are recommended", "demand_job", "Arbeitssuchend",
                    %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT]

    context "when Pensionist" do
      before do
        mock_custom_builder(builder)
      end

      context "with HOME_HOUSE_HOLD_AT_INSURANCE" do
        let(:existing_category) { builder.class::HOME_HOUSE_HOLD_AT_INSURANCE }

        it_behaves_like "proper insurances are recommended", "demand_job", "Pensionist",
                        %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT],
                        %w[PHV_IDENT]
      end
    end

    it_behaves_like "proper insurances are recommended", "demand_job", "Pensionist",
                    %w[LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT PHV_IDENT]
    include_context "mandate has house hold", "demand_job", "Pensionist"

    it_behaves_like "proper insurances are recommended", "demand_job", "Hausfrau oder Hausmann",
                    %w[PRIVATE_RETIREMENT_IDENT LEGAL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT]
    it_behaves_like "PKZ and disability insurances are recommended based on customer's age", "demand_job",
                    "Hausfrau oder Hausmann"
  end

  context "demand_hobby" do
    it_behaves_like "proper insurances are recommended", "demand_hobby", "Ich reise sehr viel",
                    %w[TRAVEL_INSURANCE_IDENT ACCIDENT_INSURANCE_IDENT]
    it_behaves_like "proper insurances are recommended", "demand_hobby", "Ich mache regelmäßig Sport",
                    ["ACCIDENT_INSURANCE_IDENT"]
    it_behaves_like "proper insurances are recommended", "demand_hobby", "Ich arbeite gerne in Haus und Garten",
                    ["ACCIDENT_INSURANCE_IDENT"]
    it_behaves_like "proper insurances are recommended", "demand_hobby",
                    "Ich verbringe sehr viel Zeit mit meiner Familie", ["ACCIDENT_INSURANCE_IDENT"]

    context "demand_hobby was answered 'Ich verbringe sehr viel Zeit mit meiner Familie'" do
      context "customer's age is 45" do
        it "does not recommend term life insurance" do
          mandate.birthdate = 45.years.ago
          create_question_with_answer("demand_hobby", "Ich verbringe sehr viel Zeit mit meiner Familie",
                                      questionnaire_response)
          apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations,
                                              Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
          ).to be_falsey
        end

        it "recommends term life when demand_family was answered 'Ich lebe alleine' and demand_kids was 'Ja'" do
          mandate.birthdate = 45.years.ago
          create_question_with_answer("demand_family", "Ich lebe alleine", questionnaire_response)
          create_question_with_answer("demand_kids", "Ja", questionnaire_response)
          create_question_with_answer("demand_hobby", "Ich verbringe sehr viel Zeit mit meiner Familie",
                                      questionnaire_response)
          apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations,
                                              Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
          ).to be_truthy
        end

        it "recommends term life insurance when demand_family was answered 'Ich lebe in einer Partnerschaft'" do
          mandate.birthdate = 45.years.ago
          create_question_with_answer("demand_family", "Ich lebe in einer Partnerschaft", questionnaire_response)
          create_question_with_answer("demand_hobby", "Ich verbringe sehr viel Zeit mit meiner Familie",
                                      questionnaire_response)
          apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations,
                                              Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
          ).to be_truthy
        end
      end

      context "customer's age is 46" do
        it "does not recommend term life insurance" do
          mandate.birthdate = 46.years.ago
          create_question_with_answer("demand_hobby", "Ich verbringe sehr viel Zeit mit meiner Familie",
                                      questionnaire_response)
          apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations,
                                              Domain::DemandCheck::RecommendationsBuilder::TERM_LIFE_INSURANCE_IDENT)
          ).to be_falsey
        end
      end
    end
  end

  context "demand_pets" do
    it_behaves_like "proper insurances are recommended", "demand_pets", "Hund",
                    %w[ANIMAL_LIABILITY_INSURANCE ANIMAL_HEALTH_INSURANCE]
    it_behaves_like "proper insurances are recommended", "demand_pets", "Katze", ["ANIMAL_HEALTH_INSURANCE"]
    it_behaves_like "proper insurances are recommended", "demand_pets", "Pferd",
                    %w[ANIMAL_LIABILITY_INSURANCE ANIMAL_HEALTH_INSURANCE]

    it 'recommends nothing if demand_pets was answered "Kleintiere"' do
      create_question_with_answer("demand_pets", "Kleintiereein", questionnaire_response)
      expect { apply_rules }.not_to change(mandate.recommendations, :count)
    end
  end
end

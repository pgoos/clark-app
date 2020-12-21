# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DemandCheck::RecommendationsBuilder, :integration do
  include RecommendationsSpecHelper
  let!(:mandate) { create(:mandate) }
  let!(:bedarfcheck_questionnaire) { create(:bedarfscheck_questionnaire) }
  let(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate, questionnaire: bedarfcheck_questionnaire)
  end

  describe "#apply_rules" do
    before(:all) do
      create_or_get_category(described_class::HOUSE_HOLD_IDENT)
      create_or_get_category(described_class::RESIDENTIAL_BUILDING_IDENT)
      create_or_get_category(described_class::KFZ_IDENT)
      create_or_get_category(described_class::CARAVAN_INSURANCE_IDENT)
      create_or_get_category(described_class::TRAILER_INSURANCE_IDENT)
      create_or_get_category(described_class::MOTOR_CYCLE_INSURANCE_IDENT)
      create_or_get_category(described_class::TERM_LIFE_INSURANCE_IDENT)
      create_or_get_category(described_class::GKV_IDENT)
      create_or_get_category(described_class::PHV_IDENT)
      create_or_get_category(described_class::LEGAL_INSURANCE_IDENT)
      create_or_get_category(described_class::ACCIDENT_INSURANCE_IDENT)
      create_or_get_category(described_class::PKZ_IDENT)
      create_or_get_category(described_class::PKV_IDENT)
      create_or_get_category(described_class::CARE_INSURANCE_IDENT)
      create_or_get_category(described_class::SERVICE_LIABILITY_INSURANCE_IDENT)
      create_or_get_category(described_class::INVALIDITY_INSURANCE_IDENT)
      create_or_get_category(described_class::ZZ_IDENT)
      create_or_get_category(described_class::TRAVEL_INSURANCE_IDENT)
      create_or_get_category(described_class::PET_OWNERS_LIABILITY_IDENT)
      create_or_get_category(described_class::DISABILITY_INSURANCE_IDENT)
      create_or_get_category(described_class::DISABILITY_SERVICES_INSURANCE_IDENT)
      create_or_get_category(described_class::LABOR_PROTECTION_INSURANCE_IDENT)
      create_or_get_category(described_class::ANIMAL_SURGERY_INSURANCE)
      create_or_get_category(described_class::PUBLIC_RETIREMENT_IDENT)
    end

    after(:all) do
      destroy_category(described_class::HOUSE_HOLD_IDENT)
      destroy_category(described_class::RESIDENTIAL_BUILDING_IDENT)
      destroy_category(described_class::KFZ_IDENT)
      destroy_category(described_class::CARAVAN_INSURANCE_IDENT)
      destroy_category(described_class::TRAILER_INSURANCE_IDENT)
      destroy_category(described_class::MOTOR_CYCLE_INSURANCE_IDENT)
      destroy_category(described_class::TERM_LIFE_INSURANCE_IDENT)
      destroy_category(described_class::GKV_IDENT)
      destroy_category(described_class::PHV_IDENT)
      destroy_category(described_class::LEGAL_INSURANCE_IDENT)
      destroy_category(described_class::ACCIDENT_INSURANCE_IDENT)
      destroy_category(described_class::PKZ_IDENT)
      destroy_category(described_class::PKV_IDENT)
      destroy_category(described_class::CARE_INSURANCE_IDENT)
      destroy_category(described_class::SERVICE_LIABILITY_INSURANCE_IDENT)
      destroy_category(described_class::INVALIDITY_INSURANCE_IDENT)
      destroy_category(described_class::ZZ_IDENT)
      destroy_category(described_class::TRAVEL_INSURANCE_IDENT)
      destroy_category(described_class::PET_OWNERS_LIABILITY_IDENT)
      destroy_category(described_class::DISABILITY_INSURANCE_IDENT)
      destroy_category(described_class::DISABILITY_SERVICES_INSURANCE_IDENT)
      destroy_category(described_class::LABOR_PROTECTION_INSURANCE_IDENT)
      destroy_category(described_class::ANIMAL_SURGERY_INSURANCE)
      destroy_category(described_class::PUBLIC_RETIREMENT_IDENT)
    end

    context "previous recommendations" do
      before do
        create_question_with_answer("demand_livingplace",
                                    "In einer gemieteten Wohnung",
                                    questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        recommendation_for(mandate.recommendations, described_class::HOUSE_HOLD_IDENT)
          .update!(level: "important")
      end

      it "updates existing recommendations level according to new rules", :integration do
        described_class.new(questionnaire_response).apply_rules

        household_recommendation = recommendation_for(mandate.recommendations,
                                                      described_class::HOUSE_HOLD_IDENT)
        expect(household_recommendation.level).to eq("recommended")
      end
    end

    context "cleanup old recommendations" do
      let(:sub_category) { create(:category) }
      let!(:old_recommendation) { create(:recommendation, category: sub_category, mandate: mandate) }

      before do
        kfz_category = Category.find_by(ident: described_class::KFZ_IDENT)
        kfz_category.category_type = Category.category_types[:umbrella]
        kfz_category.included_category_ids = [sub_category.id]
        kfz_category.save!
      end

      it "deletes the conflicting sub recommendation if parent umbrella recommendation is recommended" do
        create_question_with_answer("demand_vehicle", "Auto", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, sub_category.ident)).to be_falsey
      end

      it "does not delete the previous recommendation if it is conflicting but has an offer" do
        opportunity = create(:opportunity, mandate: mandate, category: sub_category)
        create(:active_offer, mandate: mandate, opportunity: opportunity)
        create_question_with_answer("demand_vehicle", "Auto", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, sub_category.ident)).to be_truthy
      end

      it "removes old recommendations not appearing in the newly applied rules any more" do
        category_ident = described_class::RESIDENTIAL_BUILDING_IDENT
        category = Category.find_by(ident: category_ident)
        mandate.recommendations.create!(category: category, level: :recommended)

        create_question_with_answer(
          "demand_livingplace",
          "In einer gemieteten Wohnung",
          questionnaire_response
        )
        described_class.new(questionnaire_response).apply_rules

        contained = recommendations_contain_category?(mandate.recommendations, category_ident)
        expect(contained).to be_falsey
      end
    end

    context "recommendation creation or update" do
      before do
        create_question_with_answer("demand_livingplace", "In einer gemieteten Wohnung", questionnaire_response)
      end

      it "returns a recommendation when newly created" do
        recommendations = described_class.new(questionnaire_response).apply_rules
        expect(recommendations[0]).to be_a(Recommendation)
      end

      it "it returns a recommendation that is updated" do
        described_class.new(questionnaire_response).apply_rules
        recommendation_for(mandate.recommendations, described_class::HOUSE_HOLD_IDENT).update!(level: "important")
        described_class.new(questionnaire_response).apply_rules

        recommendations = described_class.new(questionnaire_response).apply_rules
        expect(recommendations[0]).to be_a(Recommendation)
      end
    end

    context "demand_livingplace" do
      it 'recommends house hold if demand_livingplace was answered "In einer gemieteten Wohnung"' do
        create_question_with_answer("demand_livingplace", "In einer gemieteten Wohnung", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::HOUSE_HOLD_IDENT)).to be_truthy
      end

      it 'recommends house hold if demand_livingplace was answered "In meiner eigenen Wohnung"' do
        create_question_with_answer("demand_livingplace", "In meiner eigenen Wohnung", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::HOUSE_HOLD_IDENT)).to be_truthy
      end

      it 'recommends house hold if demand_livingplace was answered "In einem gemieteten Haus"' do
        create_question_with_answer("demand_livingplace", "In einem gemieteten Haus", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::HOUSE_HOLD_IDENT)).to be_truthy
      end

      it 'recommends house hold and residential property if demand_livingplace was answered "In meinem eigenen Haus"' do
        create_question_with_answer("demand_livingplace", "In meinem eigenen Haus", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::HOUSE_HOLD_IDENT)).to be_truthy
        expect(recommendations_contain_category?(mandate.recommendations, described_class::RESIDENTIAL_BUILDING_IDENT)).to be_truthy
      end
    end

    context "demand_estate" do
      context 'if demand_estate was answered "Ja, ich plane eine Immobilie zu finanzieren"' do
        it "recommends term life insurance" do
          create_question_with_answer(
            "demand_estate", "Ja, ich plane eine Immobilie zu finanzieren", questionnaire_response
          )
          described_class.new(questionnaire_response).apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)
          ).to be_truthy
        end
      end

      context 'if demand_estate was answered "Ja, ich plane eine Anschlussfinanzierung"' do
        it "recommends term life insurance" do
          create_question_with_answer(
            "demand_estate", "Ja, ich plane eine Anschlussfinanzierung", questionnaire_response
          )
          described_class.new(questionnaire_response).apply_rules
          expect(
            recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)
          ).to be_truthy
        end
      end
    end

    context "demand_vehicle" do
      it 'recommends KFZ if demand_vehicle was answered "Auto"' do
        create_question_with_answer("demand_vehicle", "Auto", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::KFZ_IDENT)).to be_truthy
      end

      it 'recommends KFZ and caravan isurance if demand_vehicle was answered "Auto, Wohnwagen"' do
        create_question_with_answer("demand_vehicle", "Auto, Wohnwagen", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::KFZ_IDENT)).to be_truthy
        expect(recommendations_contain_category?(mandate.recommendations, described_class::CARAVAN_INSURANCE_IDENT)).to be_truthy
      end

      it 'recommends trailer insurance if demand_vehicle was answered "Anhanger"' do
        create_question_with_answer("demand_vehicle", "Anhanger", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::TRAILER_INSURANCE_IDENT)).to be_truthy
      end

      context "when answer is 'Motorrad'" do
        before do
          allow(Settings).to(
            receive_message_chain("demandcheck.recommendations_builder.custom_builder")
            .and_return(nil)
          )
          allow(Settings).to(
            receive_message_chain("demandcheck.mandatory_recommendations.separate_vehicle_insurances")
              .and_return(is_vehicle_insurance_separated)
          )

          create_question_with_answer("demand_vehicle", "Motorrad", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
        end

        context "when vehicle insurances are separated" do
          let(:is_vehicle_insurance_separated) { true }

          it "doesn't recommend KFZ insurance" do
            expect(
              recommendations_contain_category?(
                mandate.recommendations, described_class::KFZ_IDENT
              )
            ).to be_falsey
          end

          it "recommends motor cycle insurance" do
            expect(
              recommendations_contain_category?(
                mandate.recommendations, described_class::MOTOR_CYCLE_INSURANCE_IDENT
              )
            ).to be_truthy
          end
        end

        context "when vehicle insurances aren't separated" do
          let(:is_vehicle_insurance_separated) { false }

          it "recommends KFZ insurance" do
            expect(
              recommendations_contain_category?(
                mandate.recommendations, described_class::KFZ_IDENT
              )
            ).to be_truthy
          end

          it "recommends motor cycle insurance" do
            expect(
              recommendations_contain_category?(
                mandate.recommendations, described_class::MOTOR_CYCLE_INSURANCE_IDENT
              )
            ).to be_truthy
          end
        end
      end
    end

    context "demand_family" do
      it 'recommends nothing if demand_family was answered "Ich bin in einer Partnerschaft"' do
        create_question_with_answer("demand_family", "Ich bin in einer Partnerschaft", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends nothing if demand_family was answered "Ich bin Single"' do
        create_question_with_answer("demand_family", "Ich bin Single", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends nothing if demand_family was answered "Ich bin verheiratet" and mandate age is > 45' do
        mandate.birthdate = 46.years.ago
        create_question_with_answer("demand_family", "Ich bin verheiratet", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends term life insurance if demand_family was answered "Ich bin verheiratet" and mandate age is <= 45' do
        mandate.birthdate = 44.years.ago
        create_question_with_answer("demand_family", "Ich bin verheiratet", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)).to be_truthy
      end
    end

    context "demand_kids" do
      it 'recommends nothing if demand_kids was answered "Nein"' do
        create_question_with_answer("demand_kids", "Nein", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends nothing if demand_kids was answered "Ja" and mandate age is > 45' do
        mandate.birthdate = 46.years.ago
        create_question_with_answer("demand_kids", "Ja", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends term life insurance if demand_kids was answered "Ja" and mandate age is <= 45' do
        mandate.birthdate = 44.years.ago
        create_question_with_answer("demand_kids", "Ja", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)).to be_truthy
      end
    end

    context "demand_hobby" do
      it 'recommends travel insurance if demand_hobby was answered "Ich reise sehr viel"' do
        create_question_with_answer("demand_hobby", "Ich reise sehr viel", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::TRAVEL_INSURANCE_IDENT)).to be_truthy
      end

      it 'recommends accident insurance if demand_hobby was answered "Ich betreibe eine gefährliche Sportart"' do
        create_question_with_answer("demand_hobby", "Ich betreibe eine gefährliche Sportart", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
      end

      it 'recommends accident insurance if demand_hobby was answered "Ich arbeite gerne in Haus und Garten"' do
        create_question_with_answer("demand_hobby", "Ich arbeite gerne in Haus und Garten", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
      end

      context "demand_hobby was answered 'Ich verbringe sehr viel Zeit mit meiner Familie'" do
        context "customer's age is 45" do
          it "recommends term life insurance" do
            mandate.birthdate = 45.years.ago
            create_question_with_answer("demand_hobby", "Ich verbringe sehr viel Zeit mit meiner Familie", questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)).to be_truthy
          end
        end

        context "customer's age is 46" do
          it "does not recommend term life insurance" do
            mandate.birthdate = 46.years.ago
            create_question_with_answer(
              "demand_hobby",
              "Ich verbringe sehr viel Zeit mit meiner Familie",
              questionnaire_response
            )

            described_class.new(questionnaire_response).apply_rules
            contain_term_insurance =
              recommendations_contain_category?(mandate.recommendations, described_class::TERM_LIFE_INSURANCE_IDENT)
            expect(contain_term_insurance).to be_falsey
          end
        end
      end
    end

    context "demand_pets" do
      it 'recommends nothing if demand_pets was answered "Nein"' do
        create_question_with_answer("demand_pets", "Nein", questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.not_to change {
          mandate.recommendations.count
        }
      end

      it 'recommends pet liability insurance if demand_pets was answered "Hund"' do
        create_question_with_answer("demand_pets", "Hund", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::PET_OWNERS_LIABILITY_IDENT)).to be_truthy
      end

      it 'recommends pet liability insurance if demand_pets was answered "Pferd"' do
        create_question_with_answer("demand_pets", "Pferd", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::PET_OWNERS_LIABILITY_IDENT)).to be_truthy
      end

      it 'recommends PHV if demand_pets was answered "Katze"' do
        create_question_with_answer("demand_pets", "Katze", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
      end

      it 'recommends PHV if demand_pets was answered "Kleintiere"' do
        create_question_with_answer("demand_pets", "Kleintiere", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
      end

      [
        "Katze",
        "Hund",
        "Pferd",
        "Katze, Hund",
        "Pferd, Katze",
        "Pferd, Hund",
        "Hund, Katze, Pferd"
      ].each do |animal|
        it "recommends animal surgery insurance if demand_pets was answered '#{animal}'" do
          create_question_with_answer("demand_pets", animal, questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ANIMAL_SURGERY_INSURANCE)).to be_truthy
        end
      end
    end

    context "demand_job" do
      context "Angestellter, bis zu 62.550" do
        before do
          create_question_with_answer("demand_job", "bis zu 62.550", questionnaire_response)
        end

        context "with statutory health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type",
                                        "gesetzlich krankenversichert",
                                        questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
          end

          it "recommends GKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
          end

          it "doesn't recommend PKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
          end
        end

        context "with private health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type",
                                        "privat krankenversichert",
                                        questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
          end

          it "doesn't recommend GKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_falsey
          end

          it "doesn't recommend PKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
          end
        end

        it "does not recommend PKV if you answered you have a GKV cause it is not feasible" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends PKZ" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end

        context "when mandate's birthdate is not set" do
          let(:mandate) { create :mandate, birthdate: nil }

          it "does not fail" do
            expect { described_class.new(questionnaire_response).apply_rules }.not_to raise_error
          end
        end

        context "when mandate over 50 years old" do
          let(:mandate) { create(:mandate, birthdate: 51.years.ago) }

          it "doesn't recommends PKZ" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
          end
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end

      context "Angestellter, uber 62.550" do
        before do
          create_question_with_answer("demand_job", "uber 62.550", questionnaire_response)
        end

        context "with statutory health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type",
                                        "gesetzlich krankenversichert",
                                        questionnaire_response)
            mandate.update!(birthdate: Time.zone.now - years_since_birthdate.years)
            described_class.new(questionnaire_response).apply_rules
          end

          context "when customer more than 50 years old" do
            let(:years_since_birthdate) { 51 }

            it "doesn't recommends PKV" do
              expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
            end

            it "doesn't recommend GKV" do
              expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_falsey
            end
          end

          context "when customer less than 50 years old" do
            let(:years_since_birthdate) { 49 }

            it "recommend PKV" do
              expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
            end

            it "doesn't recommend GKV" do
              expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_falsey
            end
          end
        end

        context "with private health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type",
                                        "privat krankenversichert",
                                        questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
          end

          it "recommends PKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
          end

          it "doesn't recommend GKV" do
            expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_falsey
          end
        end

        it "does not recommend GKV if you answered you have a gkv and user have a PKV product" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          create_product_of_category(described_class::PKV_IDENT, mandate)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_falsey
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "does recommend PKV if you answered you have a PKV and user have a GKV product" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          create_product_of_category(described_class::GKV_IDENT, mandate)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a gkv and user have a PKV product" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          create_product_of_category(described_class::PKV_IDENT, mandate)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end

      context "Selbststandig" do
        before do
          create_question_with_answer("demand_job", "Selbststandig", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end

      context "Freiberufler" do
        before do
          create_question_with_answer("demand_job", "Freiberufler", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end

      context "Beamter" do
        before do
          create_question_with_answer("demand_job", "Beamter", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends invalidity insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::INVALIDITY_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends service liability insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::SERVICE_LIABILITY_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end

      context "Auszubildender" do
        let(:job_for_bu) { create(:occupation, :is_recommended_bu) }

        before do
          create_question_with_answer("demand_job", "Auszubildender", questionnaire_response)
        end

        context "with public health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert",
                                        questionnaire_response)
          end

          it "recommends GKV (Gesetzliche Krankenversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
          end

          it "recommends DISABILITY_INSURANCE (Berufsunfähigkeitsversicherung)" do
            create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends PKZ (Private Krankenzusatzversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
          end

          it "recommends PHV (Privathaftpflichtversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
          end

          it "recommends LEGAL_INSURANCE (Rechtsschutzversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends ACCIDENT_INSURANCE (Unfallversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends PUBLIC_RETIREMENT (Gesetzliche Altersvorsorge) in state dismissed" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::PUBLIC_RETIREMENT_IDENT)
            ).to be_truthy
            expect(
              recommendation_dismissed?(mandate.recommendations, described_class::PUBLIC_RETIREMENT_IDENT)
            ).to be_truthy
          end

          it "recommends ZZ_IDENT (Zahnzusatzversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::ZZ_IDENT)).to be_truthy
          end
        end

        context "with private health insurance" do
          before do
            create_question_with_answer("demand_health_insurance_type", "privat krankenversichert",
                                        questionnaire_response)
          end

          it "recommends PKV (Private Krankenversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
          end

          it "recommends DISABILITY_INSURANCE (Berufsunfähigkeitsversicherung)" do
            create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends PHV (Privathaftpflichtversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
          end

          it "recommends LEGAL_INSURANCE (Rechtsschutzversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends ACCIDENT_INSURANCE (Unfallversicherung)" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)
            ).to be_truthy
          end

          it "recommends PUBLIC_RETIREMENT (Gesetzliche Altersvorsorge) in state dismissed" do
            described_class.new(questionnaire_response).apply_rules
            expect(
              recommendations_contain_category?(mandate.recommendations, described_class::PUBLIC_RETIREMENT_IDENT)
            ).to be_truthy
            expect(
              recommendation_dismissed?(mandate.recommendations, described_class::PUBLIC_RETIREMENT_IDENT)
            ).to be_truthy
          end
        end
      end

      context "Student" do
        before do
          create_question_with_answer("demand_job", "Student", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end
      end

      context "Schuler" do
        before do
          create_question_with_answer("demand_job", "Schuler", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends PKZ if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_truthy
        end
      end

      context "Arbeitssuchend" do
        before do
          create_question_with_answer("demand_job", "Arbeitssuchend", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "does not recommend PKV if you answered you have a GKV cause it is not feasible" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
        end

        it "recommend PKV even if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end
      end

      context "Ruhestandler" do
        before do
          create_question_with_answer("demand_job", "Ruhestandler", questionnaire_response)
        end

        it "recommends GKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::GKV_IDENT)).to be_truthy
        end

        it "does not recommends PKV if you answered you have a gkv" do
          create_question_with_answer("demand_health_insurance_type", "gesetzlich krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_falsey
        end

        it "recommends PKV if you answered you have a PKV" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKV_IDENT)).to be_truthy
        end

        it "recommends PHV" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PHV_IDENT)).to be_truthy
        end

        it "recommends ZZ insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ZZ_IDENT)).to be_truthy
        end

        it "recommends legal insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::LEGAL_INSURANCE_IDENT)).to be_truthy
        end

        it "recommends accident insurance" do
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::ACCIDENT_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend PKZ if you answered you have a pkv" do
          create_question_with_answer("demand_health_insurance_type", "privat krankenversichert", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::PKZ_IDENT)).to be_falsey
        end

        it "recommends care insurance if mandate age >= 40" do
          mandate.birthdate = 41.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_truthy
        end

        it "does not recommend care insurance if mandate age < 40" do
          mandate.birthdate = 39.years.ago
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::CARE_INSURANCE_IDENT)).to be_falsey
        end
      end
    end

    context "demand_job_title" do
      let(:job_for_bu) { create(:occupation, :is_recommended_bu) }
      let(:job_for_du) { create(:occupation, :is_recommended_du) }
      let(:job_for_labor) { create(:occupation) }

      bu_job_indications = [
        "bis zu 62.550",
        "uber 62.550",
        "Selbststandig",
        "Freiberufler",
        "Student"
      ]

      it "recommends bu if no job was entered and has a job that gets bu by default" do
        create_question_with_answer("demand_job", "Freiberufler", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)).to be_truthy
      end

      bu_job_indications.each do |job_indication|
        it "recommends bu if a job was entered that does not have mapping, e.g. #{job_indication}, and has a job that gets bu by default" do
          create_question_with_answer("demand_job", job_indication, questionnaire_response)
          create_question_with_answer("demand_job_title", "unmapped job", questionnaire_response)
          described_class.new(questionnaire_response).apply_rules
          expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)).to be_truthy
        end
      end

      it "recommends bu if no job was entered and has a job that gets du by default" do
        create_question_with_answer("demand_job", "Beamter", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_SERVICES_INSURANCE_IDENT)).to be_truthy
      end

      it "recommends bu if a job was entered that does not have mapping and has a job that gets du" do
        create_question_with_answer("demand_job", "Beamter", questionnaire_response)
        create_question_with_answer("demand_job_title", "unmapped job", questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_SERVICES_INSURANCE_IDENT)).to be_truthy
      end

      it "recommends nothing if mandate age > 50" do
        mandate.birthdate = 51.years.ago
        create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.to change { mandate.recommendations.count }.by(0)
      end

      it "recommends bu if demand_job_title was answered with a job that has bu and mandate age <= 50" do
        mandate.birthdate = 49.years.ago
        create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)).to be_truthy
      end

      it "recommends du if demand_job_title was answered with a job that has du and mandate age <= 50" do
        mandate.birthdate = 49.years.ago
        create_question_with_answer("demand_job_title", job_for_du.name, questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_SERVICES_INSURANCE_IDENT)).to be_truthy
      end

      it "recommends labor protection insurance if demand_job_title was answered with a job that has du and bu as false" do
        mandate.birthdate = 49.years.ago
        create_question_with_answer("demand_job_title", job_for_labor.name, questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::LABOR_PROTECTION_INSURANCE_IDENT)).to be_truthy
      end

      it "does not recommend bu if demand_job_title was answered with a job that has bu but does not meet the condition if exists" do
        job_for_bu.bu_recommendation_condition = {
          question: "demand_job",
          answer: "Beamter"
        }
        job_for_bu.save
        mandate.birthdate = 51.years.ago
        create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.to change { mandate.recommendations.count }.by(0)
      end

      it "does not recommend du if demand_job_title was answered with a job that has du but does not meet the condition if exists" do
        job_for_du.du_recommendation_condition = {
          question: "demand_job",
          answer: "Beamter"
        }
        job_for_du.save
        mandate.birthdate = 51.years.ago
        create_question_with_answer("demand_job_title", job_for_du.name, questionnaire_response)
        expect {
          described_class.new(questionnaire_response).apply_rules
        }.to change { mandate.recommendations.count }.by(0)
      end

      it "recommends bu if demand_job_title was answered with a job that has bu and meets the condition if exists" do
        job_for_bu.bu_recommendation_condition = {
          question: "demand_job",
          answer: "Beamter"
        }
        job_for_bu.save
        mandate.birthdate = 49.years.ago
        create_question_with_answer("demand_job", "Beamter", questionnaire_response)
        create_question_with_answer("demand_job_title", job_for_bu.name, questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_INSURANCE_IDENT)).to be_truthy
      end

      it "recommends du if demand_job_title was answered with a job that has bu and meets the condition if exists" do
        job_for_du.du_recommendation_condition = {
          question: "demand_job",
          answer: "Beamter"
        }
        job_for_du.save
        mandate.birthdate = 51.years.ago
        create_question_with_answer("demand_job", "Beamter", questionnaire_response)
        create_question_with_answer("demand_job_title", job_for_du.name, questionnaire_response)
        described_class.new(questionnaire_response).apply_rules
        expect(recommendations_contain_category?(mandate.recommendations, described_class::DISABILITY_SERVICES_INSURANCE_IDENT)).to be_truthy
      end
    end
  end
end

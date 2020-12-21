# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DemandCheck::AnswersValidator, :integration do
  include RecommendationsSpecHelper
  let(:mandate) { create(:mandate) }
  let(:bedarfcheck_questionnaire) { create(:bedarfscheck_questionnaire) }
  let(:questionnaire_response) do
    create(:questionnaire_response, mandate: mandate, questionnaire: bedarfcheck_questionnaire)
  end
  let(:subject) { described_class.new(questionnaire_response) }

  # rubocop:disable RSpec/PredicateMatcher
  context "valid?" do
    context "demand_birthdate" do
      it "is valid if value is blank" do
        question = build(:questionnaire_custom_question, question_identifier: :demand_birthdate)
        expect(subject.valid?(question, "")).to be_truthy
        expect(subject.valid?(question, nil)).to be_truthy
      end

      it "validates a format and value" do
        question = build(:questionnaire_custom_question, question_identifier: :demand_birthdate)
        expect(subject.valid?(question, "foo")).to be_falsey
        expect(subject.valid?(question, "01.01.1990")).to be_truthy
        expect(subject.valid?(question, "01/01/1990")).to be_truthy

        Timecop.freeze(Time.zone.parse("02/01/2020")) do
          expect(subject.valid?(question, "02/01/2002")).to be_truthy
          expect(subject.valid?(question, "03/01/2002")).to be_falsey
          expect(subject.valid?(question, "02/01/1900")).to be_truthy
          expect(subject.valid?(question, "02/01/1869")).to be_falsey
        end
      end
    end

    context "demand_gender" do
      it "is valid if value is blank" do
        question = build(:questionnaire_custom_question, question_identifier: :demand_gender)
        expect(subject.valid?(question, "")).to be_truthy
        expect(subject.valid?(question, nil)).to be_truthy
      end

      it "validates a format and value" do
        question = build(:questionnaire_custom_question, question_identifier: :demand_gender)
        expect(subject.valid?(question, "foo")).to be_falsey
        expect(subject.valid?(question, "male")).to be_truthy
        expect(subject.valid?(question, "female")).to be_truthy
        expect(subject.valid?(question, "divers")).to be_truthy
      end
    end

    context "demand_livingplace" do
      it "returns true if there is an answer for demand_livingplace" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_livingplace)
        expect(subject.valid?(question, "In einer gemieteten Wohnung")).to be_truthy
      end

      it "returns false if there is no answer for demand_livingplace" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_livingplace)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_estate" do
      it "returns true if there is an answer for demand_estate" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_estate)
        expect(subject.valid?(question, "Nein")).to be_truthy
      end

      it "returns false if there is no answer for demand_estate" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_estate)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_vehicle" do
      it "returns true if there is an answer for demand_vehicle" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_vehicle)
        expect(subject.valid?(question, "Auto")).to be_truthy
      end

      it "returns false if there is no answer for demand_vehicle" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_vehicle)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_priority_things" do
      it "returns true if there is an answer for demand_priority_things" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_things)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_priority_things but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_things)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_priority_things and it is a number not between 1 and 5" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_things)
        expect(subject.valid?(question, "6")).to be_falsey
      end

      it "returns false if there is no answer for demand_priority_things" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_things)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_kids" do
      it "returns true if there is an answer for demand_kids" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_kids)
        expect(subject.valid?(question, "Ja")).to be_truthy
      end

      it "returns false if there is no answer for demand_kids" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_kids)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_number_of_kids" do
      it "returns true if there is an answer for demand_number_of_kids" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_number_of_kids)
        expect(subject.valid?(question, "2")).to be_truthy
      end

      it "returns true if there is no answer for demand_number_of_kids and user answered he has no kids" do
        create_question_with_answer(:demand_kids, "Nien", questionnaire_response)
        question = create(:questionnaire_custom_question, question_identifier: :demand_number_of_kids)
        expect(subject.valid?(question, "")).to be_truthy
      end

      it "returns false if there is no answer for demand_number_of_kids and user answered ha has kids" do
        create_question_with_answer(:demand_kids, "Ja", questionnaire_response)
        question = create(:questionnaire_custom_question, question_identifier: :demand_number_of_kids)
        expect(subject.valid?(question, "")).to be_falsey
      end

      it "returns false if there is an answer for demand_number_of_kids but not a number and user answered ha has kids" do
        create_question_with_answer(:demand_kids, "Ja", questionnaire_response)
        question = create(:questionnaire_custom_question, question_identifier: :demand_number_of_kids)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is an answer for demand_number_of_kids but 0 and user answered ha has kids" do
        create_question_with_answer(:demand_kids, "Ja", questionnaire_response)
        question = create(:questionnaire_custom_question, question_identifier: :demand_number_of_kids)
        expect(subject.valid?(question, "0")).to be_falsey
      end
    end

    context "demand_job" do
      it "returns true if there is an answer for demand_job" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_job)
        expect(subject.valid?(question, "Angestellter")).to be_truthy
      end

      it "returns false if there is no answer for demand_job" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_job)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_health_insurance_type" do
      it "returns true if there is an answer for demand_health_insurance_type" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_health_insurance_type)
        expect(subject.valid?(question, "privat krankenversichert")).to be_truthy
      end

      it "returns false if there is no answer for demand_health_insurance_type" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_health_insurance_type)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_priority_existence" do
      it "returns true if there is an answer for demand_priority_existence" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_existence)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_priority_existence but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_existence)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_priority_existence and it is a number not between 1 and 5" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_existence)
        expect(subject.valid?(question, "6")).to be_falsey
      end

      it "returns false if there is no answer for demand_priority_existence" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_existence)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_risk_management" do
      it "returns true if there is an answer for demand_risk_management" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_risk_management)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_risk_management but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_risk_management)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_risk_management and it is a number not between 1 and 5" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_risk_management)
        expect(subject.valid?(question, "6")).to be_falsey
      end

      it "returns false if there is no answer for demand_risk_management" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_risk_management)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_priority_retirement" do
      it "returns true if there is an answer for demand_priority_retirement" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_retirement)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_priority_retirement but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_retirement)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_priority_retirement and it is a number not between 1 and 5" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_retirement)
        expect(subject.valid?(question, "6")).to be_falsey
      end

      it "returns false if there is no answer for demand_priority_retirement" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_priority_retirement)
        expect(subject.valid?(question, "")).to be_falsey
      end
    end

    context "demand_annual_salary" do
      it "returns true if there is an answer for demand_annual_salary" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_annual_salary)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_annual_salary but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_annual_salary)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_annual_salary but it is a negative number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_annual_salary)
        expect(subject.valid?(question, "-50")).to be_falsey
      end

      it "returns true if answer for demand_annual_salary is 0" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_annual_salary)
        expect(subject.valid?(question, "0")).to be_truthy
      end

      it "returns true if there is no answer for demand_annual_salary" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_annual_salary)
        expect(subject.valid?(question, "")).to be_truthy
      end
    end

    context "demand_monthly_spending" do
      it "returns true if there is an answer for demand_monthly_spending" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_monthly_spending)
        expect(subject.valid?(question, "1")).to be_truthy
      end

      it "returns false if there is answer for demand_monthly_spending but not a number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_monthly_spending)
        expect(subject.valid?(question, "not a number")).to be_falsey
      end

      it "returns false if there is answer for demand_monthly_spending but it is a negative number" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_monthly_spending)
        expect(subject.valid?(question, "-50")).to be_falsey
      end

      it "returns false if there is answer for demand_monthly_spending but it is 0" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_monthly_spending)
        expect(subject.valid?(question, "0")).to be_falsey
      end

      it "returns false if there is no answer for demand_monthly_spending" do
        question = create(:questionnaire_custom_question, question_identifier: :demand_monthly_spending)
        expect(subject.valid?(question, "")).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service::Varias::PensionParams do
  subject { described_class.new(questionnare_response) }

  let(:mandate) do
    create(
      :mandate,
      birthdate: "1979-01-01",
      gender: "male"
    )
  end

  let(:questionnare_response) { create(:questionnaire_response, mandate: mandate) }

  before do
    allow_any_instance_of(described_class).to(
      receive(:answers).and_return(answers)
    )
  end

  describe ".build_params" do
    context "when all params are valid" do
      context "when mode is PENSION_ACCOUNT" do
        let(:answers) do
          {
            "retirementcheck_current_statement_on_hand" => "Ja",
            "retirementcheck_total_credit" => "1234",
            "retirementcheck_statement_year" => "2019",
            "retirementcheck_statement_months" => "24",
            "retirementcheck_professional_group" => "ANGESTELLTER",
            "retirementcheck_gross_income_per_year" => "12345"
          }
        end

        it "is valid" do
          expect(subject).to be_valid
        end

        it "builds params correctly" do
          expect(subject.params).to match(
            a_hash_including(
              "dateOfBirth" => "1979-01-01",
              "gender" => "MALE",
              "occupationGroup" => "ANGESTELLTER",
              "income" => {
                "incomeType" => "GROSS",
                "incomeAmountMonthly" => 12345.0,
                "numberOfIncomesPerYear" => "EINS",
                "incomeFactorPerYear" => 0.02
              },
              "pensionAccount" => {
                "pensionAccountMode" => "PENSION_ACCOUNT",
                "numberOfInsuranceMonths" => 24,
                "pensionAccountDate" => "2019-01-01",
                "totalCreditAmount" => 1234.0
              }
            )
          )
        end
      end

      context "when mode is SIMULATION" do
        let(:answers) do
          {
            "retirementcheck_current_statement_on_hand" => "Nein",
            "retirementcheck_employed_months" => "24",
            "retirementcheck_professional_group" => "ANGESTELLTER",
            "retirementcheck_gross_income_per_year" => "12345"
          }
        end

        it "is valid" do
          expect(subject).to be_valid
        end

        it "builds params correctly" do
          expect(subject.params).to match(
            a_hash_including(
              "dateOfBirth" => "1979-01-01",
              "gender" => "MALE",
              "occupationGroup" => "ANGESTELLTER",
              "income" => {
                "incomeType" => "GROSS",
                "incomeAmountMonthly" => 12345.0,
                "numberOfIncomesPerYear" => "EINS",
                "incomeFactorPerYear" => 0.02
              },
              "pensionAccount" => {
                "pensionAccountMode" => "SIMULATION",
                "numberOfInsuranceMonths" => 24,
                "pensionAccountDate" => "#{Time.now.year}-01-01"
              }
            )
          )
        end
      end
    end

    context "when params are invalid" do
      context "when base params are wrong" do
        let(:questionnare_response) { nil }
        let(:answers) { {} }

        it "is invalid" do
          expect(subject).not_to be_valid
        end

        it "builds errors" do
          expect(subject.errors).to include(
            "Missing questionnaire_response",
            "Missing mandate",
            "Wrong gender",
            "Missing birthdate",
            "Incorrect answer for retirementcheck_current_statement_on_hand"
          )
        end
      end

      context "when mode is PENSION_ACCOUNT" do
        let(:answers) do
          {
            "retirementcheck_current_statement_on_hand" => "Ja"
          }
        end

        it "is invalid" do
          expect(subject).not_to be_valid
        end

        it "builds errors" do
          expect(subject.errors).to include(
            "Missing pension account ident retirementcheck_total_credit",
            "Missing pension account ident retirementcheck_professional_group",
            "Missing pension account ident retirementcheck_gross_income_per_year"
          )
        end
      end

      context "when mode is SIMULATION" do
        let(:answers) do
          {
            "retirementcheck_current_statement_on_hand" => "Nein"
          }
        end

        it "is invalid" do
          expect(subject).not_to be_valid
        end

        it "builds errors" do
          expect(subject.errors).to include(
            "Missing simulation ident retirementcheck_employed_months",
            "Missing simulation ident retirementcheck_professional_group",
            "Missing simulation ident retirementcheck_gross_income_per_year"
          )
        end
      end
    end
  end
end

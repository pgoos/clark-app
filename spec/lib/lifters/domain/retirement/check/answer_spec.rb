# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Check::Answer do
  subject { described_class.new(mandate, questionnaire_response, answers) }

  let(:mandate) { build :mandate }
  let(:questionnaire_response) { nil }

  def build_answer(ident, text)
    {
      answer: {
        text: text
      },
      question_id: ident
    }
  end

  describe "valid?" do
    context "when locale is DE" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:de)
      end

      context "when salary answer" do
        context "when a number" do
          context "when positive" do
            let(:answers) { build_answer("retirementcheck_annual_salary", "60000") }

            it { expect(subject).to be_valid }
          end

          context "when zero" do
            let(:answers) { build_answer("retirementcheck_annual_salary", "0") }

            it { expect(subject).to be_valid }
          end

          context "when negative" do
            let(:answers) { build_answer("retirementcheck_annual_salary", "-60000") }

            it { expect(subject).not_to be_valid }
          end
        end

        context "when not a number" do
          let(:answers) { build_answer("retirementcheck_annual_salary", "") }

          it { expect(subject).not_to be_valid }
        end
      end

      context "when birthdate answer" do
        def answer(text)
          build_answer("retirementcheck_birthdate", text)
        end

        context "when value is blank" do
          let(:answers) { build_answer("retirementcheck_birthdate", "") }

          it { expect(subject).to be_valid }
        end

        it "passes validation" do
          expect(described_class.new(mandate, nil, answer("01.01.1990"))).to be_valid
          expect(described_class.new(mandate, nil, answer("01/01/1990"))).to be_valid
          Timecop.freeze(Time.zone.parse("02/01/2020")) do
            expect(described_class.new(mandate, nil, answer("02/01/2002"))).to be_valid
            expect(described_class.new(mandate, nil, answer("02/01/1900"))).to be_valid
          end
        end

        it "does not pass validation" do
          answer_check = described_class.new(mandate, nil, answer("foo"))
          expect(answer_check).not_to be_valid
          expect(answer_check.errors.flatten).to eq ["Antwort ist nicht gültig"]

          Timecop.freeze(Time.zone.parse("02/01/2020")) do
            expect(described_class.new(mandate, nil, answer("02/01/2002"))).to be_valid
            expect(described_class.new(mandate, nil, answer("03/01/2002"))).not_to be_valid
            expect(described_class.new(mandate, nil, answer("02/01/1900"))).to be_valid
            expect(described_class.new(mandate, nil, answer("02/01/1869"))).not_to be_valid
          end
        end
      end

      context "when gender answer" do
        def answer(text)
          build_answer("retirementcheck_gender", text)
        end
        context "when value is blank" do
          let(:answers) { build_answer("retirementcheck_gender", "") }

          it { expect(subject).to be_valid }
        end

        it "validates a format and value" do
          expect(described_class.new(mandate, nil, answer("foo"))).not_to be_valid
          expect(described_class.new(mandate, nil, answer("male"))).to be_valid
          expect(described_class.new(mandate, nil, answer("female"))).to be_valid
          expect(described_class.new(mandate, nil, answer("divers"))).to be_valid
        end
      end
    end

    context "when locale is AT" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:at)
      end

      context "when retirementcheck_current_statement_on_hand answer" do
        describe "is Ja" do
          let(:answers) do
            build_answer("retirementcheck_current_statement_on_hand", "Ja")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is Nein" do
          let(:answers) do
            build_answer("retirementcheck_current_statement_on_hand", "Nein")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is another string" do
          let(:answers) do
            build_answer("retirementcheck_current_statement_on_hand", "Wrong")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
          end
        end
      end

      context "when retirementcheck_total_credit" do
        before do
          allow_any_instance_of(Domain::Retirement::Check::Rules::At).to(
            receive(:question_value).and_return("24")
          )
        end

        describe "is less than limit" do
          let(:answers) do
            build_answer("retirementcheck_total_credit", "100")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is equal to limit" do
          let(:answers) do
            build_answer("retirementcheck_total_credit", "2810.2284")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is greater than limit" do
          let(:answers) do
            build_answer("retirementcheck_total_credit", "3000")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten)
              .to eq ["Gesamtgutschrift ist, unter Berücksichtigung der angegebenen Versicherungsmonate, zu hoch"]
          end
        end
      end

      context "when retirementcheck_statement_year" do
        before { Timecop.freeze(Time.zone.parse("01/01/2020")) }

        after { Timecop.return }

        describe "is less than 4 years ago" do
          let(:answers) do
            build_answer("retirementcheck_statement_year", "2016")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten).to eq ["Der Pensionsauszug darf maximal vier Jahre alt sein."]
          end
        end

        describe "is equals to 4 years ago" do
          let(:answers) do
            build_answer("retirementcheck_statement_year", "2017")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is equals to current year" do
          let(:answers) do
            build_answer("retirementcheck_statement_year", "2020")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is greater than current year" do
          let(:answers) do
            build_answer("retirementcheck_statement_year", "2021")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten).to eq ["Der Pensionsauszug darf maximal vier Jahre alt sein."]
          end
        end
      end

      context "when retirementcheck_statement_months" do
        before do
          allow_any_instance_of(Domain::Retirement::Check::Rules::At).to(
            receive(:question_value).and_return("2017")
          )
          allow(mandate).to receive(:birthdate).and_return(Date.parse("1990-06-21"))

          Timecop.freeze(Date.new(2020, 7, 22))
        end

        after { Timecop.return }

        describe "is less than limit" do
          let(:answers) do
            build_answer("retirementcheck_statement_months", "100")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is equal to limit" do
          let(:answers) do
            build_answer("retirementcheck_statement_months", "150")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is greater than limit" do
          let(:answers) do
            build_answer("retirementcheck_statement_months", "151")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten).to eq ["Beginn der Tätigkeit darf nicht vor dem 14. Lebensjahr liegen."]
          end
        end
      end

      context "when retirementcheck_employed_months" do
        before do
          allow(mandate).to receive(:birthdate).and_return(Date.parse("1990-06-21"))

          Timecop.freeze(Date.new(2020, 7, 22))
        end

        after { Timecop.return }

        describe "is less than limit" do
          let(:answers) do
            build_answer("retirementcheck_employed_months", "180")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is equal to limit" do
          let(:answers) do
            build_answer("retirementcheck_employed_months", "186")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "is greater than limit" do
          let(:answers) do
            build_answer("retirementcheck_employed_months", "187")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten).to eq ["Aktivitäten dürfen nicht vor dem 14. Lebensjahr beginnen."]
          end
        end
      end

      context "when retirementcheck_professional_group" do
        describe "is in the list" do
          let(:answers) do
            build_answer("retirementcheck_professional_group", "Arbeiter")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        describe "isn't in the list" do
          let(:answers) do
            build_answer("retirementcheck_professional_group", "Wrong")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
          end
        end
      end

      context "when retirementcheck_gross_income_per_year" do
        context "is less than 100_000 limit" do
          let(:answers) do
            build_answer("retirementcheck_gross_income_per_year", "90000")
          end

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        context "is more than 100_000 limit" do
          let(:answers) do
            build_answer("retirementcheck_gross_income_per_year", "110000")
          end

          it "is invalid" do
            expect(subject).not_to be_valid
            expect(subject.errors.flatten)
              .to eq ["Der Pensionsrechner unterstützt ein maximales Bruttojahresgehalt von 100.000€."]
          end
        end
      end
    end
  end
end

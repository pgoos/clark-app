# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataMigration::AddAssessmentExplationToInstantAssessment do
  describe "#call" do
    shared_examples "a valid update" do
      let(:company) { create(:company) }
      let(:category) { create(:category) }
      let(:total_evaluation) { { value: 50 } }

      it "updates InstantAssessment assessment_explanation attribute" do
        instant_assessment = create(
          :instant_assessment,
          company_ident: company.ident,
          category_ident: category.ident,
          total_evaluation: total_evaluation
        )

        described_class.call
        instant_assessment.reload

        expect(instant_assessment.assessment_explanation).to eq expected_explanation
      end
    end

    context "when InstantAssessment has total_evaluation" do
      it_behaves_like "a valid update" do
        let(:expected_explanation) do
          I18n.t("data_migration.instant_advice.others.message", company: company.name, category: category.name)
        end
      end
    end

    context "when InstantAssessment has total_evaluation bigger or equals to 80" do
      it_behaves_like "a valid update" do
        let(:total_evaluation) { { value: 80 } }
        let(:expected_explanation) do
          I18n.t("data_migration.instant_advice.very_good.message", company: company.name, category: category.name)
        end
      end
    end

    context "when InstantAssessment does not have total_evaluation value" do
      let(:company) { create(:company) }
      let(:category) { create(:category) }
      let(:total_evaluation) { {} }

      it "does not update" do
        instant_assessment = create(
          :instant_assessment,
          company_ident: company.ident,
          category_ident: category.ident,
          total_evaluation: total_evaluation
        )

        expect { described_class.call }.not_to change(instant_assessment, :assessment_explanation)
      end
    end
  end
end

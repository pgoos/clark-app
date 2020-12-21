# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/constituents/instant_advice/repositories/instant_assessments_repository"
require "composites/contracts/constituents/instant_advice/entities/instant_advice"
require "composites/utils/repository/errors"

RSpec.describe Contracts::Constituents::InstantAdvice::Repositories::InstantAssessmentsRepository do
  MAPPING_KEY = "composites.contracts.constituents.instant_advice.mapping"
  subject { described_class.new }

  describe "#find_by_category_and_company", :integration do
    let!(:instant_assessment) { create(:instant_assessment) }

    it "passes scenario" do
      # valid params
      result = subject.find_by_category_and_company!(
        instant_assessment.category_ident,
        instant_assessment.company_ident
      )
      expect(result).to be_a(Contracts::Constituents::InstantAdvice::Entities::InstantAdvice)
      expect(result.category_description).to eq instant_assessment.category_description
      expect(result.total_evaluation[:value]).to eq I18n.t("#{MAPPING_KEY}.average")
      expect(result.popularity[:description]).to eq instant_assessment.popularity["description"]
      expect(result.popularity[:value]).to eq(I18n.t("#{MAPPING_KEY}.bad"))
      expect(result.customer_review[:description]).to eq instant_assessment.customer_review["description"]
      expect(result.customer_review[:value]).to eq I18n.t("#{MAPPING_KEY}.very_good")
      expect(result.coverage_degree[:description]).to eq instant_assessment.coverage_degree["description"]
      expect(result.coverage_degree[:value]).to eq(I18n.t("#{MAPPING_KEY}.good"))
      expect(result.price_level[:description]).to eq instant_assessment.price_level["description"]
      expect(result.price_level[:value]).to eq(I18n.t("#{MAPPING_KEY}.bad"))
      expect(result.claim_settlement[:description]).to eq instant_assessment.claim_settlement["description"]
      expect(result.claim_settlement[:value]).to eq(I18n.t("#{MAPPING_KEY}.bad"))

      # invalid category_ident provided
      expect {
        subject.find_by_category_and_company!(
          "non-existing-category-ident",
          instant_assessment.company_ident
        )
      }.to raise_error(Utils::Repository::Errors::Error)

      # invalid company_ident provided
      expect {
        subject.find_by_category_and_company!(
          instant_assessment.category_ident,
          "non-existing-company-ident"
        )
      }.to raise_error(Utils::Repository::Errors::Error)
    end

    context "when there are empty rating" do
      it "returns empty string as value" do
        instant_assessment = create(:instant_assessment, :without_customer_review)
        result = subject.find_by_category_and_company!(
          instant_assessment.category_ident,
          instant_assessment.company_ident
        )

        expect(result.customer_review[:value]).to eq("")
        expect(result.customer_review[:description]).to eq instant_assessment.customer_review["description"]
      end
    end
  end

  describe "#create!", :integration do
    context "when correct parameters are passed in" do
      let(:instant_assessment_schema) {
        {
          category_ident: "privathflicht",
          company_ident: "metlife123",
          category_description: "Privathflicht is a necessary category.",
          popularity: {
            "value" => 83,
            "description" => "Allianz is popular among customers."
          },
          customer_review: {
            "value" => 78,
            "description" => "Customers rated this Contract very good."
          },
          claim_settlement: {
            "value" => 100,
            "description" => "Best claim settlement history."
          },
          price_level: {
            "value" => 100,
            "description" => "Cheapest Contract in this segment."
          },
          coverage_degree: {
            "value" => 95,
            "description" => "Covers wide variety of claims."
          },
          total_evaluation: {
            "value" => 90
          }
        }
      }

      it "passing scenarios" do
        expect {
          subject.create!(instant_assessment_schema)
        }.to change {
          ::InstantAssessment.where(
            category_ident: instant_assessment_schema[:category_ident],
            company_ident: instant_assessment_schema[:company_ident]
          ).count
        }
        instant_assessment = ::InstantAssessment.find_by(
          category_ident: instant_assessment_schema[:category_ident],
          company_ident: instant_assessment_schema[:company_ident]
        )
        # verify all quality indicators are saved
        expect(instant_assessment.category_description).to eq(instant_assessment_schema[:category_description])
        expect(instant_assessment.popularity).to eq(instant_assessment_schema[:popularity])
        expect(instant_assessment.customer_review).to eq(instant_assessment_schema[:customer_review])
        expect(instant_assessment.claim_settlement).to eq(instant_assessment_schema[:claim_settlement])
        expect(instant_assessment.price_level).to eq(instant_assessment_schema[:price_level])
        expect(instant_assessment.coverage_degree).to eq(instant_assessment_schema[:coverage_degree])
        expect(instant_assessment.total_evaluation).to eq(instant_assessment_schema[:total_evaluation])
      end
    end

    context "when mandatory params are not passed in" do
      it "raises error" do
        expect {
          subject.create!(category_ident: "priva123", company_ident: "allia123")
        }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end
  end
end

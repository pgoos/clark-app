# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InsuranceStatements::InsuranceStatement do
  subject { described_class.new(mandate) }

  let(:mandate) { FactoryBot.build(:mandate) }

  describe "#top_recommendation" do
    let(:recommendation) { FactoryBot.build(:recommendation, mandate: mandate) }

    it "return number one recommendation" do
      expect_any_instance_of(Domain::Recommendations::RecommendationSelection).to \
        receive(:number_one_recommendation).and_return(recommendation)
      expect(subject.top_recommendation).to eq(category: recommendation.category.name,
                                               life_aspect: recommendation.life_aspect,
                                               questionnaire_ident: recommendation.questionnaire_identifier,
                                               category_id: recommendation.category_id)
    end
  end

  describe "#recommendations" do
    RSpec.shared_examples "has one recommendation" do
      it "has one recommendstion in the list" do
        recommendations = subject.recommendations
        expect(recommendations.count).to eq(1)

        expect(recommendations.first.category.name).to eq(recommendation.category.name)
        expect(recommendations.first.category.life_aspect).to eq(recommendation.life_aspect)
        expect(recommendations.first.questionnaire_identifier).to eq(recommendation.questionnaire_identifier)
      end
    end

    let(:mandate) { create(:mandate) }
    let(:category) { create(:category, ident: "ident", priority: 10) }
    let!(:recommendation) { create(:recommendation, mandate: mandate, dismissed: false, category: category) }

    context "with available recommendations" do
      context "with contract that matches the recommendation category" do
        context "with only one recommendation" do
          it "filters it out and return an empty list" do
            create(:product, mandate: mandate, category: recommendation.category)
            expect(subject.recommendations).to be_empty
          end
        end

        context "with more than one recommendation" do
          context "with existing product" do
            before "filters just one item out of the list" do
              category = create(:category, ident: "ident2")
              create(:product, mandate: mandate, category: category)
              create(:recommendation, mandate: mandate, dismissed: false, category: category)
            end

            include_examples "has one recommendation"
          end

          context "without existing product" do
            before do
              category = create(:category, ident: "ident2", priority: 20)
              create(:recommendation, mandate: mandate, dismissed: false, category: category)
            end

            it "sorts recommendations according category priority" do
              recommendations = subject.recommendations
              expect(recommendations.count).to eq(2)

              first_recommendation = recommendations.first
              second_recommendation = recommendations.second

              expect(first_recommendation.category.ident).to eq("ident")
              expect(second_recommendation.category.ident).to eq("ident2")
            end
          end
        end
      end
    end

    context "with dismissed recommendations" do
      let!(:dismissed_recommendation) { create(:recommendation, mandate: mandate, dismissed: true) }

      include_examples "has one recommendation"
    end
  end

  describe "#situation" do
    it "should be an array" do
      expect(subject.situation).to be_kind_of(Array)
    end

    it "should have elements with kind of Situation" do
      expect(subject.situation).to all(be_kind_of(Domain::InsuranceStatements::Situation))
    end

    it "should have exactly the size of 3" do
      expect(subject.situation.size).to be 3
    end
  end

  describe "#contracts" do
    it "shoud be an array" do
      expect(subject.contracts).to be_kind_of(Array)
    end

    it "should have elements with kind of Contract" do
      expect(subject.contracts).to all(be_kind_of(Domain::InsuranceStatements::Contract))
    end
  end

  describe "#ownership_and_property" do
    before do
      contract = double(Domain::InsuranceStatements::Contract, life_aspect: "things")
      allow(Domain::InsuranceStatements::Contract).to receive(:all).and_return([contract])
    end

    it "filters life_aspect on contracts" do
      subject.ownership_and_property.each do |contract|
        expect(contract.life_aspect).to eq "things"
      end
    end
  end

  describe "#health" do
    before do
      contract = double(Domain::InsuranceStatements::Contract, life_aspect: "health")
      allow(Domain::InsuranceStatements::Contract).to receive(:all).and_return([contract])
    end

    it "filters life_aspect on contracts" do
      subject.health.each do |contract|
        expect(contract.life_aspect).to eq "health"
      end
    end
  end

  describe "#retirement" do
    before do
      contract = double(Domain::InsuranceStatements::Contract, life_aspect: "retirement")
      allow(Domain::InsuranceStatements::Contract).to receive(:all).and_return([contract])
    end

    it "filters life_aspect on contracts" do
      subject.retirement.each do |contract|
        expect(contract.life_aspect).to eq "retirement"
      end
    end
  end

  describe "#candidate?" do
    it "should return true if mandate has any recommendation" do
      cockpit_score = {"things" => {"recommendations_count" => 1, "products_inquiries_count" => 0}}

      allow_any_instance_of(Domain::Situations::UserSituation).to \
        receive(:cockpit_score).and_return(cockpit_score)

      expect(subject.candidate?).to eq(true)
    end

    it "should return false if mandate don't have any recommendation" do
      cockpit_score = {"things" => {"recommendations_count" => 0, "products_inquiries_count" => 0}}

      allow_any_instance_of(Domain::Situations::UserSituation).to \
        receive(:cockpit_score).and_return(cockpit_score)

      expect(subject.candidate?).to eq(false)
    end
  end

  context "cockpit data" do
    before do
      allow_any_instance_of(Domain::ContractOverview::Cockpit).to \
        receive(:products_monthly_total).and_return(Money.new(5000))
      allow_any_instance_of(Domain::ContractOverview::Cockpit).to \
        receive(:products_yearly_total).and_return(Money.new(5000))
    end

    describe "#score" do
      it "should have call cockpit score" do
        expect_any_instance_of(Domain::ContractOverview::Cockpit).to receive(:score)
        subject.score
      end
    end

    describe "#annual_contribution" do
      it "should call cockpit products yearly total" do
        expect_any_instance_of(Domain::ContractOverview::Cockpit).to receive(:products_yearly_total)
        expect(subject.annual_contribution).to eq "50,00 €"
      end
    end

    describe "#monthly_contribution" do
      it "should call cockpit products monthly total" do
        expect_any_instance_of(Domain::ContractOverview::Cockpit).to receive(:products_monthly_total)
        expect(subject.monthly_contribution).to eq "50,00 €"
      end
    end
  end
end

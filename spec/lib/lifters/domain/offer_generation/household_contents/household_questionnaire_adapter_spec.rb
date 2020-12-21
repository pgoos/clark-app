require "rails_helper"

RSpec.describe Domain::OfferGeneration::HouseholdContents::HouseholdQuestionnaireAdapter do
  describe "public class methods" do
    context "responds to its methods" do
      it { expect(described_class).to respond_to(:question_id) }
      it { expect(described_class).to respond_to(:fixture_answer_value) }
    end

    context ".question_id" do
      it { expect(described_class.question_id(0)).not_to be_nil }
    end

    context ".fixture_answer_value" do
      it { expect(described_class.fixture_answer_value(1, 0)).not_to be_nil }
    end
  end

  describe "public instance methods" do
    let(:response) { n_double("response") }
    let(:adapter)  { described_class.new(response) }

    before do
      allow(response).to receive(:category)
      allow(response).to receive(:mandate)
    end

    context "responds to its methods" do
      it { expect(adapter).to respond_to(:applicable?) }
      it { expect(adapter).to respond_to(:insured_address_is_mandate_address?) }
      it { expect(adapter).to respond_to(:zero_or_one_claim?) }
    end

    context "executes methods correctly" do
      context "#applicable?" do
        it "returns true if all conditions are valid" do
          allow(response).to receive(:extract_normalized_answer)
          allow(adapter).to receive(:active_feature?).and_return(true)
          allow(adapter).to receive(:insured_address_is_mandate_address?).and_return(true)
          allow(adapter).to receive(:zero_or_one_claim?).and_return(true)
          expect(adapter.applicable?).to be_truthy
        end

        it "returns false if at least one condition isn't valid" do
          allow(adapter).to receive(:active_feature?).and_return(false)
          expect(adapter.applicable?).to be_falsy
        end
      end

      context "#insured_address_is_mandate_address?" do
        it "returns true if user answer is a mandate address" do
          allow(adapter).to receive(:answer_by).and_return("Ja")
          expect(adapter.insured_address_is_mandate_address?).to be_truthy
        end

        it "returns false if user answer isn't a mandate address" do
          allow(adapter).to receive(:answer_by).and_return("Nein")
          expect(adapter.insured_address_is_mandate_address?).to be_falsy
        end
      end

      context "#zero_or_one_claim?" do
        it "returns true if user has 0 claims" do
          allow(adapter).to receive(:answer_by).and_return("Keine Schäden")
          expect(adapter.zero_or_one_claim?).to be_truthy
        end

        it "returns true if user has 1 claim" do
          allow(adapter).to receive(:answer_by).and_return("1 Keine Schäden")
          expect(adapter.zero_or_one_claim?).to be_truthy
        end

        it "returns false if user has more than 1 claim" do
          allow(adapter).to receive(:answer_by).and_return("2 Schäden oder mehr")
          expect(adapter.zero_or_one_claim?).to be_falsy
        end
      end
    end
  end
end

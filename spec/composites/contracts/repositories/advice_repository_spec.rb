# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/advice_repository"

RSpec.describe Contracts::Repositories::AdviceRepository, :integration do
  subject { described_class.new }

  describe "#find_latest_valid_advice" do
    let!(:contract) do
      create(:contract, :with_valid_products_advice, :details_missing, questionnaire: questionnaire)
    end
    let(:product) { Product.find_by(id: contract.id) }
    let(:advice) { product.last_valid_advice }
    let(:questionnaire) { create(:questionnaire) }

    context "hide_while_instant_advice_is_on is set to true" do
      before { advice.update!(metadata: advice.metadata.merge(hide_while_instant_advice_is_on: true)) }
      
      context "instant advice is on" do
        before { allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(true) }

        it "returns nil" do
          result = subject.find_latest_valid_advice(product: product)
          expect(result).to be_kind_of Contracts::Entities::Advice
          expect(result.id).to eq nil
        end
      end

      context "instant advice is off" do
        before { allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(false) }

        it "returns the advice entity" do
          result = subject.find_latest_valid_advice(product: product)
          expect(result).to be_kind_of Contracts::Entities::Advice
          expect(result.id).to eq advice.id
          expect(result.quality).to eq :good
          expect(result.content).to eq advice.content
          expect(result.questionnaire_ident).to eq questionnaire.identifier
        end
      end
    end

    context "hide_while_instant_advice_is_on is not set" do
      it "returns the advice entity" do
        result = subject.find_latest_valid_advice(product: product)

        expect(result).to be_kind_of Contracts::Entities::Advice
        expect(result.id).to eq advice.id
        expect(result.quality).to eq :good
        expect(result.content).to eq advice.content
        expect(result.questionnaire_ident).to eq questionnaire.identifier
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Product do
  subject { described_class }

  context "total_evaluation", :integration do
    let!(:instant_advice) do
      create(:instant_assessment,
             company_ident: product.company_ident,
             category_ident: product.category_ident)
    end
    let(:product) { create(:product) }
    let(:response_obj) { double :response_obj }

    before do
      allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
    end

    it "returns nil when customer isn't permitted" do
      allow(response_obj).to receive(:failure?).and_return(true)
      expect(total_evaluation(product)).to eq nil
    end

    it "returns total_evaluation when customer is permitted" do
      allow(response_obj).to receive(:failure?).and_return(false)
      expect(total_evaluation(product)).to eq(
        I18n.t("composites.contracts.constituents.instant_advice.mapping.average")
      )
    end

    def total_evaluation(product)
      result(product)[:total_evaluation]
    end

    def result(product)
      described_class.new(product, {}).as_json
    end
  end
end

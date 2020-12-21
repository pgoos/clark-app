# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Entities::FullProduct do
  subject { described_class.new(product, {}).as_json }

  let(:product) { create(:product, advices: [advice]) }

  context "product with advice created when instant_advice is on" do
    let(:advice) { create(:advice, :created_while_instant_advice_is_on) }

    it "does not return advice" do
      expect(subject[:messages]).to be_empty
    end
  end

  context "product with advice created when instant_advice is off" do
    let(:advice) { create(:advice) }

    it "returns advice" do
      expect(subject[:messages]).not_to be_empty
    end
  end

  context "shared attribute" do
    let(:product) { create(:product, :under_management) }

    it "returns a boolean" do
      expect(subject[:shared]).to be_in([true, false])
    end

    it "returns false as default" do
      expect(subject[:shared]).to be false
    end

    context "when is third party" do
      let(:product) { create(:product, :under_management, insurance_holder: :third_party) }

      it "returns true" do
        expect(subject[:shared]).to be true
      end
    end
  end
end

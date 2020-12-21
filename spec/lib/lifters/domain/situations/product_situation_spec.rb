# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::ProductSituation do
  subject { described_class.new(product) }

  let(:mandate) { create(:mandate, state: "accepted") }
  let(:product) { create(:product, mandate: mandate) }

  let!(:advice) {
    create(:advice,
           topic: product,
           acknowledged: false,
           mandate: mandate)
  }

  context "#last_advice_is_acknowledged?" do
    it "is false if there is no ackowledged advice" do
      advice.update(acknowledged: false)
      expect(subject.last_advice_is_acknowledged?).to eq(false)
    end

    it "is true if there is an acknowledged advice" do
      advice.update(acknowledged: true)
      expect(subject.last_advice_is_acknowledged?).to eq(true)
    end
  end

  context "#last_advice_is_acknowledged?" do
    it "is true if there is a recent advice" do
      expect(subject.interacted_with_during_past_30_days).to eq(true)
    end

    it "is false if there is a recent advice" do
      mandate.interactions.destroy_all
      expect(subject.interacted_with_during_past_30_days).to eq(false)
    end
  end
end

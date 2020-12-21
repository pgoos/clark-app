# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::AdviceSituation do
  subject { Domain::Situations::UserSituation }

  context ".interacted_with_during_past_30_days" do
    let(:mandate) { create(:mandate) }
    let(:admin) { create(:admin) }
    let(:interaction_list) { [] }

    it "with mandate with nil interactions" do
      allow(mandate).to receive(:interactions).and_return(nil)

      situation = subject.new(mandate)
      expect(situation.interacted_with_during_past_30_days).to eq(false)
    end
  end

  context ".not_read_gkv_advice?" do
    let(:mandate) { create(:mandate) }
    let(:category) { create(:category_gkv) }
    let!(:product) { create(:product_gkv, state: "under_management", mandate: mandate) }

    it "is true with no interactions" do
      situation = subject.new(mandate)
      expect(situation.not_read_gkv_advice?).to eq(true)
    end

    it "is false with interactions" do
      create(:interaction_advice, product: product)
      situation = subject.new(mandate)

      expect(situation.not_read_gkv_advice?).to eq(false)
    end
  end
end

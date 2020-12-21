# frozen_string_literal: true

require "rails_helper"

describe TemporaryRoboAdvisorJob, type: :job do
  describe ".perform" do
    let(:mandate) { create(:mandate) }
    let(:product) { create(:product, mandate: mandate) }
    let!(:advice) { create(:advice, :reoccurring_advice, topic: product) }
    let(:rule_id) { "7.1" }
    let(:admin)   { create(:admin) }

    before do
      allow(Robo::AdminRepository).to receive(:random).and_return(admin.id)
    end

    it do
      expect(product.advices.count).to eq(1)
      subject.perform(rule_id, advice.id)
      expect(product.advices.reload.count).to eq(2)
    end
  end
end

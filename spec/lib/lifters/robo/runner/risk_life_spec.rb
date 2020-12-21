# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::RiskLife", type: :integration do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin) { create(:advice_admin) }
    let(:plan) { create(:plan, category: category, company: company) }
    let(:company) { create(:company) }
    let(:product) { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_dental }
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with good insurance" do
      let(:rule_id) { "16.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "catch all" do
      let(:rule_id) { "16.4" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

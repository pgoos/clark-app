# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::AccidentInsurance" do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin)   { create(:advice_admin) }
    let(:plan)     { create(:plan, category: category, company: company, subcompany: subcompany) }
    let(:company)  { create(:company) }
    let(:product)  { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_accident_insurace }
    let(:subcompany) do
      create :subcompany, company: company
    end
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with good coverage" do
      let(:rule_id) { "5.2" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with bad coverage" do
      let(:rule_id) { "5.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

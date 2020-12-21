# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::CarInsurance" do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin)   { create(:advice_admin) }
    let(:plan)     { create(:plan, category: category, company: company, subcompany: subcompany) }
    let(:company)  { create(:company) }
    let(:product)  { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_car_insurance }
    let(:subcompany) do
      create :subcompany, company: company
    end
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with good coverage" do
      let(:rule_id) { "101.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with contract about to expire" do
      let(:rule_id) { "101.2" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with no other rule evaluating to true" do
      let(:rule_id) { "101.1" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

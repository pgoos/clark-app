# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::LegalProtection" do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin)   { create(:advice_admin) }
    let(:plan)     { create(:plan, category: category, company: company, subcompany: subcompany) }
    let(:company)  { create(:company) }
    let(:product)  { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_legal }
    let(:subcompany) do
      create :subcompany, company: company
    end
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with company in whitelist" do
      let(:rule_id) { "3.1" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company das9a42a4d2 rolanc8aa07" do
      let(:rule_id) { "3.2" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company devk0584d87" do
      let(:rule_id) { "3.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company deura71ed9b" do
      let(:rule_id) { "3.6" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company allref35893" do
      let(:rule_id) { "3.7" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with no other rule evaluating to true" do
      let(:rule_id) { "3.8" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

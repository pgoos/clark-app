# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::Household" do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin)   { create(:advice_admin) }
    let(:plan)     { create(:plan, category: category, company: company, subcompany: subcompany) }
    let(:company)  { create(:company) }
    let(:product)  { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_hr }
    let(:subcompany) do
      create :subcompany, company: company
    end
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "when good insurance with company ident haftpe6e5c1 or ammer0658ce" do
      let(:rule_id) { "4.1" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when contract_ended_at is more than 12 months and not special company" do
      let(:rule_id) { "4.2" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when contract_started_at more than 3 years ago and not special company" do
      let(:rule_id) { "4.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company ident asste505166" do
      let(:rule_id) { "4.8" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when good insurance with company ident hukcoceec6c or huk2466e28b" do
      let(:rule_id) { "4.9" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when good insurance with company ident gener339e31" do
      let(:rule_id) { "4.10" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when no rule apply" do
      let(:rule_id) { "4.7" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

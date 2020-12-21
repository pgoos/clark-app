# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::Retirement", type: :integration do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin) { create(:advice_admin) }
    let(:plan) { create(:plan, category: category, company: company) }
    let(:company) { create(:company) }
    let(:product) { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_retirement }
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with company ident from 4 or 5 star companies" do
      let(:rule_id) { "29.1" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company ident from 3 star companies" do
      let(:rule_id) { "29.2" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company ident from 2 or 1 star companies and contract started before 2011" do
      let(:rule_id) { "29.3" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with company ident from 2 or 1 star companies and contract started after 2011" do
      let(:rule_id) { "29.4" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "catch all" do
      let(:rule_id) { "29.5" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end
  end
end

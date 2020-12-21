# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

describe "Robo::Runner::PHV" do
  subject { Robo::Runner.call(product) }

  include_context "with mocked roboadvisor"

  describe "#call" do
    let!(:admin)   { create(:advice_admin) }
    let(:plan)     { create(:plan, category: category, company: company, subcompany: subcompany) }
    let(:company)  { create(:company) }
    let(:product)  { create(:product, :year_premium, plan: plan) }
    let(:category) { create :category_phv }
    let(:subcompany) do
      create :subcompany, company: company
    end
    let(:interaction) { Interaction.find_by topic: product, mandate: product.mandate }

    context "with company in whitelist" do
      let(:rule_id) { "2.6.b" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "with sachschaden coverage" do
      context "when value is bigger than 10_000_000" do
        let(:rule_id) { "2.10" }

        it do
          expect { subject }.to change(Interaction::Advice, :count).by(1)
          expect(interaction.rule_id).to eq rule_id
        end
      end

      context "when values is under 10_000_000" do
        let(:rule_id) { "2.1" }

        it do
          expect { subject }.to change(Interaction::Advice, :count).by(1)
          expect(interaction.rule_id).to eq rule_id
        end
      end
    end

    context "with vermogensschaden coverage" do
      context "when value is bigger than 10_000_000" do
        let(:rule_id) { "2.10" }

        it do
          expect { subject }.to change(Interaction::Advice, :count).by(1)
          expect(interaction.rule_id).to eq rule_id
        end
      end

      context "when values is under 10_000_000" do
        let(:rule_id) { "2.2" }

        it do
          expect { subject }.to change(Interaction::Advice, :count).by(1)
          expect(interaction.rule_id).to eq rule_id
        end
      end
    end

    context "when premium is bigger or equal to 900_000" do
      let(:rule_id) { "2.4" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when premium is less than 600_000" do
      let(:rule_id) { "2.5" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when whitelist company and in payment list" do
      let(:rule_id) { "2.7" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when company is COSMOS" do
      let(:rule_id) { "2.13" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when company is DEBEKA" do
      let(:rule_id) { "2.14" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when company is ASSTEL" do
      let(:rule_id) { "2.15" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq rule_id
      end
    end

    context "when company is WGV" do
      let(:rule_id) { "2.16" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq "2.16"
      end
    end

    context "when company is PROV" do
      let(:rule_id) { "2.17" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq "2.17"
      end
    end

    context "when company is HUK" do
      let(:rule_id) { "2.18" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq "2.18"
      end
    end

    context "when company is VGH" do
      let(:rule_id) { "2.19" }

      it do
        expect { subject }.to change(Interaction::Advice, :count).by(1)
        expect(interaction.rule_id).to eq "2.19"
      end
    end
  end
end

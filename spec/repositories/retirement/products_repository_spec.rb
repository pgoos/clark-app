# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::ProductsRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#all" do
    let(:mandate) { create :mandate }
    let(:category) { create :category, :direktversicherung }
    let(:default_product_attrs) { {mandate: mandate} }

    def setup_product(*traits, **attrs)
      create :product, *traits, **default_product_attrs.merge(attrs)
    end

    context "with state product" do
      let!(:product) { setup_product :retirement_state_category }

      it { expect(repo.all(mandate)).to include product }
    end

    context "with equity product" do
      let!(:product) { setup_product :retirement_equity_category }

      it { expect(repo.all(mandate)).not_to include product }
    end

    context "with retirement products" do
      let!(:product) { setup_product :retirement_personal_category }

      context "when retirement product is not active" do
        before { create :retirement_product, :out_of_scope, product: product }

        it { expect(repo.all(mandate)).not_to include product }
      end

      context "when retirement product is active" do
        before { create :retirement_product, :details_available, product: product }

        it { expect(repo.all(mandate)).to include product }
      end
    end

    context "with other than retirement products" do
      let!(:product) { create :product_gkv, mandate: mandate }

      it { expect(repo.all(mandate)).not_to include product }
    end

    context "without plan" do
      let!(:product) { setup_product :customer_provided, plan: nil }

      it { expect(repo.all(mandate)).not_to include product }

      context "but with retirement extenstion" do
        context "in state created" do
          before { create :retirement_product, :created, product: product }

          it { expect(repo.all(mandate)).to include product }
        end

        context "in state details_available" do
          before { create :retirement_product, :details_available, product: product }

          it { expect(repo.all(mandate)).not_to include product }
        end
      end
    end

    context "analysis_state verification" do
      context "with active analysis_state" do
        context "in analysis_state details_missing" do
          let(:product) { setup_product :retirement_state_category, analysis_state: "details_missing" }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).to include product }
        end

        context "in analysis_state under_analysis" do
          let(:product) { setup_product :retirement_state_category, analysis_state: "under_analysis" }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).to include product }
        end

        context "in analysis_state analysis_failed" do
          let(:product) { setup_product :retirement_state_category, analysis_state: "analysis_failed" }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).to include product }
        end

        context "in analysis_state details_complete" do
          let(:product) { setup_product :retirement_state_category, analysis_state: "details_complete" }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).to include product }
        end

        context "in analysis_state nil" do
          let(:product) { setup_product :retirement_state_category, analysis_state: nil }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).to include product }
        end
      end

      context "with inactive analysis_state" do
        context "in analysis_state customer_canceled_analysis" do
          let(:product) { setup_product :retirement_state_category, analysis_state: "customer_canceled_analysis" }

          before { create :retirement_product, product: product }

          it { expect(repo.all(mandate)).not_to include product }
        end
      end
    end

    it_behaves_like " a contract overview products with state conditions" do
      let(:default_product_attrs) do
        {mandate: mandate, category: create(:category, :direktversicherung)}
      end
    end

    it_behaves_like " a contract overview products with contract ended at conditions" do
      let(:default_product_attrs) do
        {mandate: mandate, category: create(:category, :direktversicherung)}
      end
    end
  end
end

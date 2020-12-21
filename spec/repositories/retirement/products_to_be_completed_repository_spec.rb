# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::ProductsToBeCompletedRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#filter_by" do
    it "orders by updated_at column of retirement_products table" do
      product1 = create :product, :customer_provided, plan: nil
      product2 = create :product, :customer_provided, plan: nil

      create :retirement_product, product: product1, updated_at: 2.minutes.ago
      create :retirement_product, product: product2, updated_at: 1.minute.ago

      expect(repo.filter_by.to_a).to eq [product2, product1]
    end

    it "filters out inactive mandates" do
      product1 = create :product,
                        :customer_provided,
                        :with_retirement_product,
                        plan: nil,
                        mandate: create(:mandate, :accepted)
      product2 = create :product,
                        :customer_provided,
                        :with_retirement_product,
                        plan: nil,
                        mandate: create(:mandate, :in_creation)
      product3 = create :product,
                        :customer_provided,
                        :with_retirement_product,
                        plan: nil,
                        mandate: create(:mandate, :created)
      create :product,
             :customer_provided,
             :with_retirement_product,
             plan: nil,
             mandate: create(:mandate, :rejected)

      expect(repo.filter_by.to_a).to match_array [product1, product2, product3]
    end

    context "when product is in non retirement category" do
      let(:product) { create :product, :suhk_product, :details_available }

      it { expect(repo.filter_by).not_to include product }
    end

    context "when product is in retirement category" do
      context "with details_available state" do
        let(:product) { create :product, :retirement_state_category, :details_available }

        context "with retirement product extension" do
          context "with created state" do
            before { create :retirement_product, :created, product: product }

            it { expect(repo.filter_by).to include product }
          end

          context "with details_available state" do
            before { create :retirement_product, :details_available, product: product }

            it { expect(repo.filter_by).not_to include product }
          end

          context "with information_required state" do
            before { create :retirement_product, :information_required, product: product }

            it { expect(repo.filter_by).to include product }
          end
        end

        context "without retirement product extension" do
          it { expect(repo.filter_by).not_to include product }
        end
      end

      context "with customer_provided state" do
        let!(:product) { create :product, :retirement_state_category, :customer_provided }

        context "without retirement extension" do
          it { expect(repo.filter_by).to include product }
        end

        context "with retirement extension" do
          context "with details_available state" do
            context "with initial forecast" do
              let!(:retirement_product) do
                create :retirement_product, :details_available, :initial_forecast, product: product
              end

              it { expect(repo.filter_by).not_to include product }
            end

            context "with customer forecast" do
              before do
                create :retirement_product, :details_available, :customer_forecast, product: product
              end

              it { expect(repo.filter_by).not_to include product }
            end

            context "with document forecast" do
              before do
                create :retirement_product, :details_available, :document_forecast, product: product
              end

              it { expect(repo.filter_by).not_to include product }
            end
          end

          context "with information_required state" do
            before { create :retirement_product, :information_required, product: product }

            it { expect(repo.filter_by).to include product }
          end

          context "with in out_of_scope state" do
            before { create :retirement_product, :out_of_scope, product: product }

            it { expect(repo.filter_by).not_to include product }
          end
        end
      end
    end

    context "without plan" do
      let(:product) { create :product, :customer_provided, plan: nil }

      it { expect(repo.filter_by).not_to include product }

      context "with retirement extension" do
        before { create :retirement_product, product: product }

        it { expect(repo.filter_by).to include product }
      end

      context "without retirement product extension" do
        it { expect(repo.filter_by).not_to include product }
      end
    end

    context "when filtering state" do
      let(:product1) { create(:product, :customer_provided, plan: nil) }
      let!(:retirement_product1) { create(:retirement_product, state: :details_available, product: product1) }

      let(:product2) { create(:product, :customer_provided, plan: nil) }
      let!(:retirement_product2) { create(:retirement_product, state: :information_required, product: product2) }

      it "filters by state correctly" do
        products = repo.filter_by(state: "information_required")
        expect(products).to eq [product2]

        products = repo.filter_by(state: "details_available")
        expect(products).to eq [product2, product1]
      end
    end

    context "when filtering by category" do
      let(:category1) { create(:category, ident: Domain::Retirement::CategoryIdents::CATEGORY_IDENT_OVERALL_PERSONAL) }
      let(:product1) { create(:product, :customer_provided, category: category1) }
      let!(:retirement_product1) { create(:retirement_product, state: :information_required, product: product1) }

      let(:category2) do
        create(:category, ident: Domain::Retirement::CategoryIdents::CATEGORY_IDENT_PRIVATE_RENTENVERSICHERUNG)
      end

      let(:product2) { create(:product, :customer_provided, category: category2) }
      let!(:retirement_product2) { create(:retirement_product, state: :created, product: product2) }

      it "filters by category correctly" do
        products = repo.filter_by(category_ids: [])
        expect(products).to eq [product2, product1]

        products = repo.filter_by(category_ids: [1200])
        expect(products).to eq []

        products = repo.filter_by(category_ids: [product2.plan.category_id])
        expect(products).to eq [product2]
      end
    end

    context "with order params" do
      it "orders by information_requested_at" do
        product1 = create :product, :customer_provided, plan: nil
        product2 = create :product, :customer_provided, plan: nil

        create :retirement_product, product: product1, information_requested_at: 2.days.ago
        create :retirement_product, product: product2, information_requested_at: 1.day.ago

        result = repo.filter_by(order: "information_requested_at_asc").to_a
        expect(result).to eq [product1, product2]

        result = repo.filter_by(order: "information_requested_at_desc").to_a
        expect(result).to eq [product2, product1]
      end
    end
  end
end

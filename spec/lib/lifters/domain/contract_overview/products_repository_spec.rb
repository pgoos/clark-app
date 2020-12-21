# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::ProductsRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#all" do
    let(:mandate) { create(:mandate, :accepted, :with_user) }
    let(:plan)    { create(:plan, :suhk) }

    def setup_product(*traits, **attrs)
      default = {plan: plan}
      build_stubbed :product, *traits, **default.merge(attrs)
    end

    it "includes mandate's products" do
      create :product
      product = create(:product, :under_management, plan: plan, mandate: mandate)
      expect(repo.all(mandate)).to include(product)
    end

    context "shared_products" do
      before do
        create(:product, :under_management, plan: plan, mandate: mandate)
      end

      context "when feature flags is ON" do
        it "includes shared products" do
          shared_product = create(
            :product,
            :under_management,
            :shared_contract,
            plan: plan,
            mandate: mandate
          )

          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)

          products = repo.all(mandate)
          expect(products.size).to be(2)
          expect(products).to include(shared_product)
        end
      end

      context "when feature flags is OFF" do
        it "does not include shared products" do
          shared_product = create(
            :product,
            :under_management,
            :shared_contract,
            plan: plan,
            mandate: mandate
          )

          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(false)

          products = repo.all(mandate)
          expect(products.size).to be(1)
          expect(products).not_to include(shared_product)
        end
      end
    end

    context "when product is in equity category" do
      let(:plan) { create(:plan, :equity) }

      it "does not include product" do
        product = create(:product, :under_management, plan: plan, mandate: mandate)

        expect(repo.all(mandate)).not_to include(product)
      end
    end

    context "when product does not have a plan" do
      it "does not include product" do
        product = create(:product, :customer_provided, plan: nil, mandate: mandate)

        expect(repo.all(mandate)).not_to include(product)
      end
    end

    context "analysis_state verification" do
      context "with active analysis_state" do
        [
          "details_missing",
          "under_analysis",
          "analysis_failed",
          "details_complete",
          nil
        ].each do |analysis_state|
          context "when analysis_state is #{analysis_state}" do
            it "includes product in mandate's products" do
              product = create(
                :product,
                :customer_provided,
                analysis_state: analysis_state,
                plan: plan,
                mandate: mandate
              )

              expect(repo.all(mandate)).to include(product)
            end
          end
        end
      end

      context "with inactive analysis_state" do
        context "in analysis_state customer_canceled_analysis" do
          let(:product) { setup_product :customer_provided, analysis_state: "customer_canceled_analysis" }

          it { expect(repo.all(mandate)).not_to include product }
        end
      end
    end

    context "state verification" do
      context "with active state" do
        %w[
          customer_provided
          details_available
          terminated
        ].each do |state|
          context "when state is #{state}" do
            it "includes product in mandate's products" do
              product = create(
                :product,
                state: state,
                plan: plan,
                mandate: mandate
              )

              product_ids = subject.all(mandate).map(&:id)
              expect(product_ids).to include(product.id)
            end
          end
        end
      end

      context "with inactive state" do
        %w[
          canceled
          offered
        ].each do |state|
          context "when state is #{state}" do
            it "does not include product in mandate's products" do
              product = create(
                :product,
                state: state,
                plan: plan,
                mandate: mandate
              )

              product_ids = subject.all(mandate).map(&:id)
              expect(product_ids).not_to include(product.id)
            end
          end
        end
      end
    end

    context "contract_ended_at" do
      [
        [
          "when contract end date is blank",
          nil
        ],
        [
          "when contract end date has not passed",
          Date.current + 1.day
        ],
        [
          "when contract end date is today",
          Date.current
        ]
      ].each do |context, contract_ended_at|
        context context do
          it "includes product in mandate's products" do
            product = create(
              :product,
              state: :under_management,
              plan: plan,
              mandate: mandate,
              contract_ended_at: contract_ended_at
            )

            product_ids = subject.all(mandate).map(&:id)
            expect(product_ids).to include(product.id)
          end
        end
      end

      context "when contract end date has passed" do
        it "does not include product in mandate's products" do
          product = create(
            :product,
            state: :under_management,
            plan: plan,
            mandate: mandate,
            contract_ended_at: Date.current - 1.day
          )

          product_ids = subject.all(mandate).map(&:id)
          expect(product_ids).not_to include(product.id)
        end
      end
    end
  end

  describe "#find" do
    let(:mandate) { object_double Mandate.new }

    # rubocop:disable RSpec/SubjectStub
    it "searches in #all collection" do
      products = [
        object_double(Product.new, id: 1),
        object_double(Product.new, id: 2),
        object_double(Product.new, id: 3)
      ]
      expect(repo).to receive(:all).with(mandate).and_return(products)
      product = repo.find(mandate, 2)
      expect(product).to eq products[1]
    end
    # rubocop:enable RSpec/SubjectStub
  end
end

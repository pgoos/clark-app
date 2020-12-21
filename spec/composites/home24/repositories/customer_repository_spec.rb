# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/customer_repository"

RSpec.describe Home24::Repositories::CustomerRepository do
  subject(:repository) { described_class.new }

  include_context "home24 with order"

  let(:order_number) { home24_order_number }
  let(:home24_mandate) { create(:mandate, :home24) }

  describe "#find" do
    it "returns aggregated entity with aggregated data" do
      customer = repository.find(home24_mandate.id)

      expect(customer).to be_kind_of Home24::Entities::Customer
      expect(customer.id).to eq(home24_mandate.id)
      expect(customer.home24_source).to be_truthy
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repository.find(9999)).to be_nil
      end
    end
  end

  describe "#enable_home24" do
    let(:mandate) { create(:mandate, :with_lead) }

    it "enables home24 source and returns entity" do
      customer = repository.enable_home24(mandate.id)

      expect(customer).to be_kind_of Home24::Entities::Customer
      expect(customer.id).to eq(mandate.id)
      expect(customer.home24_source).to be_truthy
      expect(mandate.reload.lead.source_data["adjust"]["network"]).to eq("home24")
    end
  end

  describe "#save_home24_order_number" do
    it "adds the home24 order number and returns the entity" do
      customer = repository.save_order_number(home24_mandate.id, order_number)

      expect(customer).to be_kind_of Home24::Entities::Customer
      expect(customer.order_number).to eq(order_number)
      expect(home24_mandate.reload.loyalty["home24"]["order_number"]).to eq(order_number)
    end
  end

  describe "#order_number_unique" do
    context "when no other mandate with that number exists" do
      it "returns true" do
        expect(repository.order_number_unique?(order_number)).to be_truthy
      end
    end

    context "when mandate with that order number exists" do
      let(:loyalty) { { "home24": { "order_number" => order_number } } }

      it "returns false" do
        create(
          :mandate,
          :accepted,
          :home24,
          loyalty: loyalty
        )

        expect(repository.order_number_unique?(order_number)).to be_falsey
      end
    end
  end

  describe "#customers_to_export" do
    let(:active_product_states) { Home24::Entities::Product::ACTIVE_STATES }
    let(:category_idents_to_exclude) {
      Home24::Interactors::InitiateCustomersExport::NOT_COUNTABLE_CATEGORY_IDENTIFIERS
    }
    let!(:home24_mandate) { create(:mandate, :home24, state: :accepted) }
    let!(:plan) { create(:plan, ident: "test_ident") }

    it "returns customer entity that has to be exported" do
      customers = repository.customers_to_export(plan.ident, active_product_states, category_idents_to_exclude)

      expect(customers.length).to eq(1)
      expect(customers[0]).to be_kind_of Home24::Entities::Customer
      expect(customers[0].id).to eq(home24_mandate.id)
    end

    context "when max_no_of_customers is passed" do
      let(:max_no_of_customers) { 1 }
      let!(:second_home24_mandate) { create(:mandate, :home24, state: :accepted) }

      it "returns only exact number of customers as max_no_of_customers" do
        customers = repository.customers_to_export(
          plan.ident,
          active_product_states,
          category_idents_to_exclude,
          max_no_of_customers: max_no_of_customers
        )

        expect(customers.length).to eq(1)
        expect(customers[0].id).to eq(home24_mandate.id)
      end
    end

    context "when forced_customer_ids is passed" do
      let!(:second_home24_mandate) {
        create(
          :mandate,
          :home24,
          state: :accepted,
          export_state: Home24::Entities::Customer::ExportState::COMPLETED
        )
      }

      let(:forced_customer_ids) { [second_home24_mandate.id] }

      it "returns only customer that id was passed on forced_customer_ids" do
        customers = repository.customers_to_export(
          plan.ident,
          active_product_states,
          category_idents_to_exclude,
          forced_customer_ids: forced_customer_ids
        )

        expect(customers.length).to eq(1)
        expect(customers[0].id).to eq(second_home24_mandate.id)
      end
    end

    context "when there is forced customer which has export state as initiated" do
      let!(:second_home24_mandate) {
        create(
          :mandate,
          :home24,
          state: :accepted,
          export_state: Home24::Entities::Customer::ExportState::INITIATED
        )
      }

      let(:forced_customer_ids) { [second_home24_mandate.id] }

      it "doesn't return any customer" do
        customers = repository.customers_to_export(
          plan.ident,
          active_product_states,
          category_idents_to_exclude,
          forced_customer_ids: forced_customer_ids
        )

        expect(customers.length).to eq(0)
      end
    end

    context "when customer is already initiated to export" do
      before do
        home24_mandate.loyalty["home24"] ||= {}
        home24_mandate.loyalty["home24"]["export_state"] = Home24::Entities::Customer::ExportState::INITIATED
        home24_mandate.save
      end

      it "doesn't return any customer to export" do
        customers = repository.customers_to_export(plan.ident, active_product_states, category_idents_to_exclude)

        expect(customers.length).to eq(0)
      end
    end

    context "when product is already created" do
      let!(:product) {
        create(:product, mandate: home24_mandate, plan: plan, state: Product::STATES_OF_ACTIVE_PRODUCTS[0])
      }

      it "doesn't return any customer to export" do
        customers = repository.customers_to_export(plan.ident, active_product_states, category_idents_to_exclude)

        expect(customers.length).to eq(0)
      end
    end
  end

  describe "#products_count" do
    let!(:home24_mandate) { create(:mandate, :home24, state: :accepted) }
    let!(:product) {
      create(:product, mandate: home24_mandate, state: Product::STATES_OF_ACTIVE_PRODUCTS[0])
    }

    it "returns 1" do
      count = repository.products_count(home24_mandate.id, Product::STATES_OF_ACTIVE_PRODUCTS, [])

      expect(count).to eq(1)
    end

    context "when there is not any product for customer" do
      it "returns 0" do
        count = repository.products_count(99, Product::STATES_OF_ACTIVE_PRODUCTS, [])

        expect(count).to eq(0)
      end
    end

    context "when product of customer is not on the state queried " do
      it "returns 0" do
        count = repository.products_count(99, Product::STATES_OF_ACTIVE_PRODUCTS[1..-1], [])

        expect(count).to eq(0)
      end
    end

    context "when category ident of product is excluded" do
      it "returns 0" do
        count = repository.products_count(99, Product::STATES_OF_ACTIVE_PRODUCTS, [product.category.ident])

        expect(count).to eq(0)
      end
    end
  end

  describe "#save_condition_values" do
    let(:contract_details_condition) { true }
    let(:consultation_waiving_condition) { true }

    it "saved the conditions values under info column" do
      repository.save_condition_values(home24_mandate.id, contract_details_condition, consultation_waiving_condition)
      home24_mandate.reload

      home24_conditions = home24_mandate.info["home24_conditions"]
      expect(home24_conditions["contract_details"]).to be_truthy
      expect(home24_conditions["consultation_waiving"]).to be_truthy
    end
  end

  describe "#save_export_state" do
    let(:export_state) { "initiated" }

    it "saves export state for customer" do
      customer = repository.save_export_state(home24_mandate.id, export_state)

      expect(customer.home24_data["export_state"]).to eq(export_state)
      expect(Mandate.find(customer.id).loyalty["home24"]["export_state"]).to eq(export_state)
    end
  end

  describe "#ready_to_export_customer_ids" do
    let!(:home24_mandate) { create(:mandate, :home24, state: :accepted) }
    let(:free_plan_ident) { Home24::Entities::Product::FREE_PLAN_IDENT }
    let(:product_states) { Home24::Entities::Product::ACTIVE_STATES }
    let(:category_idents_to_exclude) {
      Home24::Interactors::InitiateCustomersExport::NOT_COUNTABLE_CATEGORY_IDENTIFIERS
    }
    let(:free_plan) { create(:plan, ident: free_plan_ident) }

    context "when mandate has product with free plan" do
      let!(:free_product) {
        create(:product, mandate: home24_mandate, state: Home24::Entities::Product::ACTIVE_STATES[1], plan: free_plan)
      }

      it "returns empty array" do
        customer_ids =
          repository.ready_to_export_customer_ids(free_plan_ident, product_states, category_idents_to_exclude)

        expect(customer_ids).to be_kind_of Array
        expect(customer_ids).to be_empty
      end
    end

    context "when mandate does not have product with free plan" do
      it "returns array containing mandate id" do
        customer_ids =
          repository.ready_to_export_customer_ids(free_plan_ident, product_states, category_idents_to_exclude)

        expect(customer_ids).to be_kind_of Array
        expect(customer_ids[0]).to eq(home24_mandate.id)
      end
    end

    context "when mandate is already initiated for home24 export" do
      before do
        home24_mandate.loyalty["home24"] ||= {}
        home24_mandate.loyalty["home24"]["export_state"] = Home24::Entities::Customer::ExportState::INITIATED
        home24_mandate.save
      end

      it "returns array without mandate id" do
        customer_ids =
          repository.ready_to_export_customer_ids(free_plan_ident, product_states, category_idents_to_exclude)

        expect(customer_ids).to be_kind_of Array
        expect(customer_ids).to be_empty
      end
    end
  end
end

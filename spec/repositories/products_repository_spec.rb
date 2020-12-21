# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsRepository, :integration do
  describe ProductsRepository::ProductsQueryBuilder, :integration do
    let(:accepted_mandate) { create(:mandate, :accepted) }
    let(:created_mandate)  { create(:mandate, :created) }

    describe "#filter_by_mandate_state" do
      context "when there are products that belong to mandates in various states" do
        let!(:product_accepted_mandate) { create(:product, :ordered, mandate: accepted_mandate) }
        let!(:product_created_mandate)  { create(:product, :ordered, mandate: created_mandate)  }

        it "returns query that selects only products that belong to mandates in target state" do
          result = described_class.new.filter_by_mandate_state(:accepted).query.to_a
          expect(result.length).to  eq(1)
          expect(result.first).to   eq(product_accepted_mandate)
        end
      end

      context "when there are no products that belong to mandates in target state" do
        before do
          create(:product, :ordered, mandate: created_mandate)
        end

        it "returns query that selects an empty array" do
          result = described_class.new.filter_by_mandate_state(:accepted).query.to_a
          expect(result).to be_empty
        end
      end
    end

    describe "#filter_by_product_state" do
      let!(:product_ordered)            { create(:product, :ordered, mandate: accepted_mandate)           }
      let!(:product_customer_provided)  { create(:product, :customer_provided, mandate: created_mandate)  }
      let!(:product_under_management)   { create(:product, :under_management, mandate: accepted_mandate)  }
      let!(:product_takeover_requested) { create(:product, :takeover_requested, mandate: created_mandate) }

      context "when there are products in various states" do
        it "returns query that selects only product in selected range of states" do
          result = described_class.new.filter_by_product_state(%w[ordered takeover_requested]).query.to_a
          expect(result.length).to  eq(2)
          expect(result).to         include(product_ordered)
          expect(result).to         include(product_takeover_requested)
        end
      end

      context "when there are no products in selected state" do
        it "returns query that selects an empty array" do
          result = described_class.new.filter_by_product_state(["termination_pending"]).query.to_a
          expect(result).to be_empty
        end
      end
    end

    describe "#filter_by_product_state_or_analysis_state" do
      context "when there are products in target product/analysis states" do
        let(:c_1_target_product_states) { %w[ordered customer_provided] }
        let(:c_2_target_analysis_states) { %w[details_complete] }

        let(:c_1_mandate) { create(:mandate, :accepted) }
        let(:c_2_mandate) { create(:mandate, :accepted, :mandate_customer) }

        let!(:product_c_1_ordered)              { create(:product, :ordered,              mandate: c_1_mandate) }
        let!(:product_c_1_customer_provided)    { create(:product, :customer_provided,    mandate: c_1_mandate) }
        let!(:product_c_1_termination_pending)  { create(:product, :termination_pending,  mandate: c_1_mandate) }
        let!(:product_c_2_details_missing)      { create(:product, :details_missing,      mandate: c_2_mandate) }
        let!(:product_c_2_details_complete)     { create(:product, :details_complete,     mandate: c_2_mandate) }

        it "returns query that selects only products in selected states for C1 and C2 customers" do
          result = described_class
                   .new
                   .filter_by_product_state_or_analysis_state(c_1_target_product_states, c_2_target_analysis_states)
                   .query
                   .to_a
          expect(result.length).to eq(3)
          expect(result).to include(product_c_1_ordered)
          expect(result).to include(product_c_1_customer_provided)
          expect(result).to include(product_c_2_details_complete)
        end
      end
    end

    describe "#filter_by_contract_expiration" do
      context "when there are products with various target end_at and annual_maturity values" do
        let!(:product_end_at_4_m) do
          create(:product, :ordered, mandate: created_mandate, contract_ended_at: Time.current + 4.months)
        end
        let!(:product_annual_maturity_in_4m) do
          create(:product, :customer_provided, mandate: accepted_mandate, contract_ended_at: nil,
                 annual_maturity: (Time.current + 4.months).strftime("%m-%d"))
        end
        let!(:product_end_at_2_m) do
          create(:product, :under_management, mandate: created_mandate, contract_ended_at: Time.current + 2.months)
        end
        let!(:product_annual_maturity_in_3m) do
          create(:product, :takeover_requested, mandate: accepted_mandate, contract_ended_at: nil,
                 annual_maturity: (Time.current + 3.months).strftime("%m-%d"))
        end

        context "when there are products with target values" do
          it "returns query that selects only products with target end_at and annual_maturity values" do
            result = described_class.new.filter_by_contract_expiration(Date.current + 4.months).query.to_a
            expect(result.length).to  eq(2)
            expect(result).to         include(product_end_at_4_m)
            expect(result).to         include(product_annual_maturity_in_4m)
          end
        end

        context "when there are no products with target values" do
          it "returns query that selects an empty array" do
            result = described_class.new.filter_by_contract_expiration(Date.current + 5.months).query.to_a
            expect(result).to be_empty
          end
        end
      end
    end

    describe "#filter_by_category_margin_level" do
      context "when there are products with various margin_level categories" do
        let(:low_margin_category)    { create(:category, :low_margin) }
        let(:medium_margin_category) { create(:category, :medium_margin) }
        let(:high_margin_category)   { create(:category, :high_margin) }

        let!(:lm_product) { create(:product, category: low_margin_category)    }
        let!(:mm_product) { create(:product, category: medium_margin_category) }
        let!(:hm_product) { create(:product, category: high_margin_category)   }

        it "returns a query that selects only products with target category margin_level" do
          result = described_class.new.filter_by_category_margin_level(:low).query.to_a
          expect(result.length).to eq(1)
          expect(result.first).to  eq(lm_product)
        end
      end
    end

    describe "#filter_by_category_ident" do
      let(:category_811edefa)    { create(:category, ident: "811edefa") }
      let(:category_2d2aaf4a)    { create(:category, ident: "2d2aaf4a") }
      let(:category_9637977d)    { create(:category, ident: "9637977d") }

      let!(:product_811edefa) { create(:product, category: category_811edefa) }
      let!(:product_2d2aaf4a) { create(:product, category: category_2d2aaf4a) }
      let!(:product_9637977d) { create(:product, category: category_9637977d) }

      describe "_inclusion" do
        context "when there are products with target include category idents" do
          it "returns a query that selects ONLY products with target category idents" do
            result = described_class.new.filter_by_category_ident_inclusion("811edefa").query.to_a
            expect(result.length).to eq(1)
            expect(result.first).to  eq(product_811edefa)
          end
        end
      end

      describe "_exclusion" do
        context "when there are products with target exclude category idents" do
          it "returns a query that selects all products EXCEPT products with target category idents" do
            result = described_class.new.filter_by_category_ident_exclusion(%w[811edefa 2d2aaf4a]).query.to_a
            expect(result.length).to eq(1)
            expect(result.first).to  eq(product_9637977d)
          end
        end
      end
    end

    describe "#filter_by_non_direct_sales" do
      let(:accepted_mandate) { create(:mandate, :accepted, :with_user) }
      let(:direct_sales_mandate) do
        create(:user, :with_mandate, source_data: { adjust: { network: "online_ds" } }).mandate
      end

      let!(:product_with_direct_sales)    { create(:product, :customer_provided, mandate: direct_sales_mandate) }
      let!(:product_without_direct_sales) { create(:product, :customer_provided, mandate: accepted_mandate) }

      it "retrieves only non direct sales products" do
        result = described_class.new.filter_by_non_direct_sales.query.to_a
        expect(result.size).to be(1)
        expect(result.first).to eq(product_without_direct_sales)
      end
    end

    describe "#filter_by_owner" do
      let(:mandate_owned_by_clark) { create(:mandate, :accepted, :owned_by_clark) }
      let(:mandate_owned_by_partner) { create(:mandate, :accepted, :owned_by_partner) }

      let!(:product_owned_by_clark)   { create(:product, :customer_provided, mandate: mandate_owned_by_clark) }
      let!(:product_owned_by_partner) { create(:product, :customer_provided, mandate: mandate_owned_by_partner) }

      it "retrieves products by given owner" do
        result = described_class.new.filter_by_owner("clark").query.to_a
        expect(result.size).to be(1)
        expect(result.first).to eq(product_owned_by_clark)
      end
    end

    describe "#filter_by_valid_mandate" do
      shared_examples "return only valid products" do
        before { create(:product, :customer_provided) }

        it do
          product = create(:product, :customer_provided, mandate: mandate)

          expect(Product.count).to be(2)

          result = described_class.new.filter_by_valid_mandate.query.to_a

          expect(result.size).to be(1)
          expect(result.first).to eq(product)
        end
      end

      context "when clark 1 accepted mandate" do
        let(:mandate) { create(:mandate, :accepted) }

        it_behaves_like "return only valid products"
      end

      context "when clark 2 mandate_customer" do
        let(:mandate) { create(:mandate, :mandate_customer) }

        it_behaves_like "return only valid products"
      end
    end

    describe "filter_by_contract_expiration_in_period" do
      let(:mandate) { create(:mandate, :accepted) }
      let(:in_period_date) { Date.new(2020, 12, 2) }
      let(:not_in_period_date) { Date.new(2020, 4, 14) }

      before do
        create(:product, :under_management, mandate: mandate, contract_ended_at: not_in_period_date)
      end

      context "when product's contract_ended_at is in the period" do
        let(:beginning) { Date.new(2020, 12, 1) }
        let(:ending) { Date.new(2021, 1, 31) }

        it "returns that product" do
          product_in_period = create(:product, :under_management, mandate: mandate, contract_ended_at: in_period_date)
          expect(Product.count).to be(2)

          result = described_class.new.filter_by_contract_expiration_in_period(beginning, ending).query.to_a
          expect(result.length).to be(1)
          expect(result.first).to eq(product_in_period)
        end
      end
    end
  end

  describe "#exists_contract_with_number?" do
    context "when there is product with same number" do
      let(:product) { create(:product) }

      it "returns true" do
        result = described_class.exists_contract_with_number?(product.number)

        expect(result).to be true
      end
    end

    context "when shared product has the same number" do
      let(:product) { create(:product, :shared_contract) }

      it "returns false" do
        result = described_class.exists_contract_with_number?(product.number)

        expect(result).to be false
      end
    end
  end

  describe "#retrieve_products_ending_at" do
    let(:mandate) { create(:mandate, :accepted) }

    context "when products have a active state" do
      before do
        create(:product, :ordered, mandate: mandate, contract_ended_at: Time.current + 2.months)
        create(:product, :ordered, mandate: mandate, contract_ended_at: Time.current + 5.months)
      end

      it "returns only products with 4 months left to end" do
        product = create(:product, :ordered, mandate: mandate, contract_ended_at: Time.current + 4.months)

        products = described_class.retrieve_products_ending_at(Time.current + 4.months)

        expect(products.length).to be(1)
        expect(products[0].id).to be(product.id)
        expect(products[0].category_name).to eq(product.category_name)
      end
    end

    context "when products don't have a active state" do
      before do
        create(:product, :ordered, mandate: mandate, contract_ended_at: Time.current + 2.months)
        create(:product, :canceled, mandate: mandate, contract_ended_at: Time.current + 4.months)
      end

      it "does not returns products" do
        products = described_class.retrieve_products_ending_at(Time.current + 4.months)

        expect(products.length).to be(0)
      end
    end

    context "when products have a matched annual_maturity" do
      before do
        create(:product, :ordered, mandate: mandate, contract_ended_at: nil,
               annual_maturity: (Time.current + 2.months).strftime("%m-%d"))
        create(:product, :ordered, mandate: mandate, contract_ended_at: nil,
               annual_maturity: (Time.current + 5.months).strftime("%m-%d"))
      end

      it "returns only products with 4 months left to end" do
        product = create(:product, :ordered, mandate: mandate, contract_ended_at: nil,
                         annual_maturity: (Time.current + 4.months).strftime("%m-%d"))

        products = described_class.retrieve_products_ending_at(Time.current + 4.months)

        expect(products.length).to be(1)
        expect(products[0].id).to be(product.id)
      end
    end
  end

  describe "#retrieve_products_eligible_for_cancellation_notification" do
    let(:exclusion_category_ident)  { "408b8a4d" }
    let(:ending_at)                 { Time.current + 4.months }
    let(:mandate)                   { create(:mandate, :with_user, :accepted, :owned_by_clark) }
    let(:category)                  { create(:category, :low_margin, ident: "2edc0680") }
    let!(:product) do
      create(:product, :under_management, mandate: mandate, category: category, contract_ended_at: ending_at)
    end

    before do
      create(:product, :termination_pending, mandate: mandate, category: category, contract_ended_at: ending_at)
    end

    context "when there is a product eligible for cancellation notification" do
      shared_examples "returns this product and bolt out others" do
        it do
          result = described_class
                   .retrieve_products_eligible_for_cancellation_notification(ending_at, exclusion_category_ident)

          expect(result.length).to   eq(1)
          expect(result.first.id).to eq(product.id)
        end
      end

      context "when customer is CLARK 1 accepted mandate" do
        it_behaves_like "returns this product and bolt out others"
      end

      context "when customer is CLARK 2 mandate customer" do
        let(:mandate) { create(:mandate, :with_user, :mandate_customer, :owned_by_clark) }

        it_behaves_like "returns this product and bolt out others"
      end
    end

    context "when there are no products eligible for cancellation notification" do
      shared_examples "returns an empty result" do
        it do
          result = described_class
                   .retrieve_products_eligible_for_cancellation_notification(ending_at, exclusion_category_ident)

          expect(result).to be_empty
        end
      end

      context "when there are no products owned by an accepted mandate" do
        let(:mandate) { create(:mandate, :with_user, :created, :owned_by_clark) }

        it_behaves_like "returns an empty result"
      end

      context "when there are no products owned by a non-direct-sales mandate" do
        let(:mandate) do
          mandate = create(:user, :with_mandate, source_data: { adjust: { network: "online_ds" } }).mandate
          mandate.state = "accepted"
          mandate.tos_accepted_at = Time.zone.now.advance(days: -1)
          mandate.owner_ident = "clark"
          mandate.save
          mandate
        end

        it_behaves_like "returns an empty result"
      end

      context "when there are no products owned by a mandate with eligible owner" do
        let(:mandate) { create(:mandate, :with_user, :accepted, :owned_by_partner) }

        it_behaves_like "returns an empty result"
      end

      context "when there are no low margin products" do
        let(:category) { create(:category, :medium_margin, ident: "2edc0680") }

        it_behaves_like "returns an empty result"
      end

      context "when there are no products in target states" do
        let!(:product) do
          create(:product, :termination_pending, mandate: mandate, category: category, contract_ended_at: ending_at)
        end

        it_behaves_like "returns an empty result"
      end

      context "when there are products in allowed category" do
        let(:exclusion_category_ident) { "2edc0680" }

        it_behaves_like "returns an empty result"
      end

      context "when there are products with target ending_at or annual_maturity values" do
        let!(:product) do
          ending_at = Time.current + 5.months
          create(:product, :under_management, mandate: mandate, category: category, contract_ended_at: ending_at)
        end

        it_behaves_like "returns an empty result"
      end
    end
  end

  describe "#retrieve_kfz_products_eligible_for_cancellation_notification" do
    let(:mandate) { create(:mandate, :accepted, :with_user, :owned_by_clark) }
    let(:motor_insurance_category) { create(:category, ident: "c20f02bb", margin_level: :low) }
    let(:plan) { create(:plan, :activated, category: motor_insurance_category) }

    before do
      [2, 5].each do |number|
        create(
          :product,
          :under_management,
          mandate: mandate,
          plan: plan,
          contract_ended_at: Time.current + number.months
        )
      end
    end

    shared_examples "doesn't return products" do
      it do
        expect(Product.count).to be(3)

        products = described_class.retrieve_kfz_products_eligible_for_cancellation_notification(Date.current + 4.months)

        expect(products.length).to be(0)
      end
    end

    context "Mandate Filters" do
      before do
        create(:product, :under_management, mandate: mandate, plan: plan, contract_ended_at: Time.current + 4.months)
      end

      context "when mandate doesn't have a valid Clark 1 state" do
        let(:mandate) { create(:mandate, :created, :with_user, :owned_by_clark) }

        it_behaves_like "doesn't return products"
      end

      context "when mandate doesn't have a valid Clark 2 state" do
        let(:mandate) { create(:mandate, :prospect_customer, :owned_by_clark) }

        it_behaves_like "doesn't return products"
      end

      context "when mandate is not owned by clark or n26" do
        let(:mandate) { create(:mandate, :accepted, :with_user, :owned_by_partner) }

        it_behaves_like "doesn't return products"
      end

      context "when mandate is a direct sales" do
        before do
          mandate.user.update(source_data: { adjust: { network: "fb-malburg" } })
        end

        it_behaves_like "doesn't return products"
      end
    end

    context "Category filters" do
      before do
        create(:product, :under_management, mandate: mandate, plan: plan, contract_ended_at: Time.current + 4.months)
      end

      context "when category is high margin" do
        let(:motor_insurance_category) { create(:category, ident: "c20f02bb", margin_level: "high") }

        it_behaves_like "doesn't return products"
      end

      context "when category is medium marging" do
        let(:motor_insurance_category) { create(:category, ident: "c20f02bb", margin_level: "medium") }

        it_behaves_like "doesn't return products"
      end
    end

    context "Product filters" do
      context "when product state is invalid" do
        before do
          create(
            :product,
            :canceled,
            analysis_state: :under_analysis,
            mandate: mandate,
            plan: plan,
            contract_ended_at: Time.current + 4.months
          )
        end

        it_behaves_like "doesn't return products"
      end
    end

    context "when all requirements are matched" do
      it "returns products" do
        product = create(
          :product,
          :under_management,
          mandate: mandate,
          plan: plan,
          contract_ended_at: Time.current + 4.months
        )

        products = described_class.retrieve_kfz_products_eligible_for_cancellation_notification(Date.current + 4.months)

        expect(products.length).to be(1)
        expect(products[0].id).to be(product.id)
        expect(products[0].category_name).to eq(product.category_name)
      end
    end
  end

  describe "#retrieve_first_batch_kfz_products_for_cancellation_notification" do
    let(:mandate) { create(:mandate, :accepted, :with_user, :owned_by_clark) }
    let(:plan) { create(:plan, :activated, category: motor_insurance_category) }
    let(:motor_insurance_category) { create(:category, ident: "c20f02bb", margin_level: :low) }

    context "when there are products" do
      it "returns products with even id" do
        expected_products = create_list(
          :product,
          6,
          :under_management,
          mandate: mandate,
          plan: plan,
          contract_ended_at: Date.new(2020, 12, 2)
        ).reject { |p| p.id.odd? }.map(&:id)

        products = described_class.retrieve_first_batch_kfz_products_for_cancellation_notification

        expect(products.length).to be(expected_products.length)
        expect(products.map(&:id)).to match_array(expected_products)
      end
    end

    context "when there are no products" do
      it "returns empty" do
        products = described_class.retrieve_first_batch_kfz_products_for_cancellation_notification

        expect(products.length).to be(0)
      end
    end
  end

  describe "#retrieve_second_batch_kfz_products_for_cancellation_notification" do
    let(:first_batch_date) { Time.new(2020, 10, 1, 8, 0) }
    let(:mandate) { create(:mandate, :accepted, :with_user, :owned_by_clark) }
    let(:plan) { create(:plan, :activated, category: motor_insurance_category) }
    let(:motor_insurance_category) { create(:category, ident: "c20f02bb", margin_level: :low) }

    context "when there are products" do
      it "returns products with odd id" do
        expected_products = create_list(
          :product,
          6,
          :under_management,
          mandate: mandate,
          plan: plan,
          created_at: Date.new(2020, 9, 3),
          contract_ended_at: Date.new(2020, 12, 2)
        ).reject { |p| p.id.even? }.map(&:id)

        products = described_class.retrieve_second_batch_kfz_products_for_cancellation_notification(first_batch_date)

        expect(products.length).to be(expected_products.length)
        expect(products.map(&:id)).to match_array(expected_products)
      end
    end

    context "when there are products created after first batch" do
      it "returns products with odd id and extra created products" do
        expected_products = create_list(
          :product,
          6,
          :under_management,
          mandate: mandate,
          plan: plan,
          created_at: Date.new(2020, 9, 3),
          contract_ended_at: Date.new(2020, 12, 2)
        ).reject { |p| p.id.even? }.map(&:id)

        expected_products << create(
          :product,
          :under_management,
          id: 100,
          mandate: mandate,
          plan: plan,
          created_at: Date.new(2020, 10, 3),
          contract_ended_at: Date.new(2020, 12, 2)
        ).id

        products = described_class.retrieve_second_batch_kfz_products_for_cancellation_notification(first_batch_date)

        expect(products.length).to be(expected_products.length)
        expect(products.map(&:id)).to match_array(expected_products)
      end
    end

    context "when there are no products" do
      it "returns empty" do
        products = described_class.retrieve_second_batch_kfz_products_for_cancellation_notification(first_batch_date)

        expect(products.length).to be(0)
      end
    end
  end
end

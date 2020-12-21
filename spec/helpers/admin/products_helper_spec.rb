# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProductsHelper do
  describe "#products_for_insurance_situation", :integration do
    let!(:product) { create(:product) }
    let!(:other_mandate_products) do
      [
        create(:product, :details_available, category: product.category, mandate: product.mandate),
        create(:product, :ordered, category: product.category, mandate: product.mandate),
        create(:product, :canceled, category: product.category, mandate: product.mandate)
      ]
    end

    it "returns default insurance situation" do
      products = helper.products_for_insurance_situation(product)
      expect(products).to include(other_mandate_products[0])
      expect(products).to include(other_mandate_products[1])
      expect(products).not_to include(other_mandate_products[2])
    end
  end

  describe "#default_insurance_situation" do
    let(:products) do
      [
        double(:product, category_name: "cat1", number: 123, company_name: "cmp1", plan_name: "plan1"),
        double(:product, category_name: "cat2", number: 345, company_name: "cmp2", plan_name: "plan2")
      ]
    end

    it "returns default insurance situation" do
      default_insurance_situation = helper.default_insurance_situation(products)
      expect(default_insurance_situation).to include(products[0].category_name)
      expect(default_insurance_situation).to include(products[0].number.to_s)
      expect(default_insurance_situation).to include(products[0].company_name)
      expect(default_insurance_situation).to include(products[0].plan_name)
      expect(default_insurance_situation).to include(products[1].category_name)
      expect(default_insurance_situation).to include(products[1].number.to_s)
      expect(default_insurance_situation).to include(products[1].company_name)
      expect(default_insurance_situation).to include(products[1].plan_name)
      expect(default_insurance_situation).to include("; ")
    end
  end

  describe "default_reason_for_consultation" do
    let(:products) do
      [
        double(:product, category_name: "cat1", number: 123, company_name: "cmp1",
          plan_name: "plan1", category_ident: "4fb3e303"),
        double(:product, category_name: "cat2", number: 345, company_name: "cmp2",
          plan_name: "plan2", category_ident: "4fb3e3")
      ]
    end

    it "returns default reason for consultation" do
      default_reason_for_consultation = helper.default_reason_for_consultation([products[0]])
      expect(default_reason_for_consultation).to eq(
        I18n.t("admin.products.documents.advisory_documentation.reason_for_consultation.4fb3e303")
      )
    end

    it "returns empty when translation mismatch for category" do
      default_reason_for_consultation = helper.default_reason_for_consultation([products[1]])
      expect(default_reason_for_consultation).to eq("")
    end
  end

  describe "#advisory_documentation_generation_allowed?" do
    let(:admin) { double(:admin) }

    before { allow(helper).to receive(:current_admin).and_return(admin) }

    context "product in order_pending or details_available state" do
      let(:product) { build(:product, :order_pending) }
      let(:product_in_details_available) {
        build(:product, :details_available)
      }

      context "product has no advisory documentation" do
        before { allow(product).to receive(:has_advisory_documentation?).and_return(false) }

        context "admin has access to admin/advisory_documentations#create" do
          before do
            allow(admin).to receive(:permitted_to?).with(
              controller: "admin/advisory_documentations", action: "create"
            ).and_return(true)
          end

          it "returns true when state is order_pending" do
            expect(helper.advisory_documentation_generation_allowed?(product)).to eq true
          end

          it "returns true when state is details_available" do
            expect(
              helper.advisory_documentation_generation_allowed?(product_in_details_available)
            ).to eq true
          end
        end

        context "admin has no access do admin/advisory_documentations#create" do
          before do
            allow(admin).to receive(:permitted_to?).with(
              controller: "admin/advisory_documentations", action: "create"
            ).and_return(false)
          end

          it "returns false" do
            expect(helper.advisory_documentation_generation_allowed?(product)).to eq false
          end
        end
      end

      context "product has advisory documentation" do
        before { allow(product).to receive(:has_advisory_documentation?).and_return(true) }

        context "admin has access to admin/advisory_documentations#create" do
          before do
            allow(admin).to receive(:permitted_to?).with(
              controller: "admin/advisory_documentations", action: "create"
            ).and_return(true)
          end

          it "returns false" do
            expect(helper.advisory_documentation_generation_allowed?(product)).to eq false
          end
        end
      end
    end

    context "product not in order_pending state" do
      let(:product) { build(:product, :ordered) }

      context "product has no advisory documentation" do
        before { allow(product).to receive(:has_advisory_documentation?).and_return(true) }

        context "admin has access do admin/advisory_documentations#create" do
          before do
            allow(admin).to receive(:permitted_to?).with(
              controller: "admin/advisory_documentations", action: "create"
            ).and_return(true)
          end

          it "returns false" do
            expect(helper.advisory_documentation_generation_allowed?(product)).to eq false
          end
        end
      end
    end
  end

  describe "#creating_from_inquiry?" do
    let(:inquiry) { build(:inquiry) }
    let(:new_product1) { build(:product, inquiry: inquiry, mandate: nil) }
    let(:new_product2) { build(:product, inquiry: nil) }
    let(:new_product3) { create(:product) }

    it do
      expect(helper.creating_from_inquiry?(new_product1)).to eq true
      expect(helper.creating_from_inquiry?(new_product2)).to eq false
      expect(helper.creating_from_inquiry?(new_product3)).to eq false
    end
  end

  describe "#creating_from_mandate?" do
    let(:mandate) { build(:mandate) }
    let(:new_product1) { build(:product, inquiry: nil, mandate: mandate) }
    let(:new_product2) { build(:product, mandate: nil) }
    let(:new_product3) { create(:product) }

    it do
      expect(helper.creating_from_mandate?(new_product1)).to eq true
      expect(helper.creating_from_mandate?(new_product2)).to eq false
      expect(helper.creating_from_mandate?(new_product3)).to eq false
    end
  end

  describe "#subcompanies_for_product_form" do
    let(:company) { create(:company) }
    let(:category) { create(:category) }
    let(:plan) { create(:plan, company: company) }
    let(:product) { create(:product, plan: plan, category: category) }
    let!(:subcompany1) { create(:subcompany, verticals: [category.vertical], company: company) }
    let!(:subcompany2) { create(:subcompany, company: company) }

    it "returns subcompanies based on product's category" do
      expect(helper.subcompanies_for_product_form(product).size).to eq 1
    end
  end

  describe "#plans_for_product_form" do
    let(:company) { create(:company) }
    let(:category) { create(:category) }
    let(:product) { create(:product, plan: plan1, category: category) }
    let(:plan1) { create(:plan, company: company, category: category) }
    let!(:plan2) { create(:plan, company: company) }

    it "returns plans based on product's category" do
      expect(helper.plans_for_product_form(product).size).to eq 1
    end
  end
end

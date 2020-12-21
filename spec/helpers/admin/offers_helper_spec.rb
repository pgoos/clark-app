# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OffersHelper do
  describe "#plan_options_for_offer_option" do
    let(:category) { build_stubbed(:category) }

    context "with a new offer_option" do
      let(:product) { Product.new }
      let(:offer_option) { OfferOption.new(product: product) }
      let(:category) { build_stubbed(:category) }

      it "returns an empty array" do
        response = helper.plan_options_for_offer_option(offer_option, category)
        collection = helper.options_from_collection_for_select([], :name, :id)
        expect(response).to eq collection
      end
    end

    context "with an old product" do
      let(:offer_option) { build_stubbed(:old_product_option) }

      it "returns an empty array" do
        response = helper.plan_options_for_offer_option(offer_option, category)
        plan_id = offer_option.product.plan.id
        collection = helper.options_from_collection_for_select([offer_option.product.plan], :id, :name, plan_id)
        expect(response).to eq collection
      end
    end

    context "with plans from the subcompany" do
      let(:category) { plan_with_coverages.category }
      let(:offer_option) { create(:offer_option, product: product) }
      let(:product) { create(:product, plan: plan) }
      let(:subcompany) { create(:subcompany) }
      let!(:plan_with_coverages) { create(:plan, :with_stubbed_coverages, subcompany: subcompany) }
      let!(:plan) { create(:plan, name: "admin/offers_helper_spec:40", category: category, subcompany: subcompany) }
      let!(:plan_with_different_category) do
        create(:plan, :with_stubbed_coverages, name: "different plan", subcompany: subcompany)
      end

      it "returns an empty array" do
        response = helper.plan_options_for_offer_option(offer_option, category)
        collection = helper.options_from_collection_for_select([plan_with_coverages], :id, :name)
        expect(response).to eq collection
      end
    end
  end

  describe "#company_options_for_offer_option", :integration do
    let!(:category) { create(:category, vertical: vertical) }
    let!(:vertical) { create(:vertical) }
    let!(:company) { create(:company, name: "company name") }
    let!(:other_company) { create(:company, name: "other company") }
    let!(:subcompany) { create(:subcompany, company: company, verticals: [vertical]) }
    let(:offer_option) { double(:offer_option) }

    context "when category is present" do
      it "returns related company with selected tag" do
        allow(offer_option).to receive_message_chain(:product, :company, :id).and_return(company.id)
        response = helper.company_options_for_offer_option(offer_option, category)
        expect(response).to eq "<option selected=\"selected\" value=\"#{company.id}\">#{company.name}</option>"
      end
    end

    context "when category is not passed" do
      it "returns all companies" do
        allow(offer_option).to receive_message_chain(:product, :company, :id).and_return(nil)
        response = helper.company_options_for_offer_option(offer_option)
        expect(response).to include "<option value=\"#{company.id}\">#{company.name}</option>"
        expect(response).to include "<option value=\"#{other_company.id}\">#{other_company.name}</option>"
      end
    end
  end

  describe "#subcompany_options_for_product_form" do
    context "with a new offer_option" do
      let(:product) { Product.new }
      let(:offer_option) { OfferOption.new(product: product) }
      let(:category) { build_stubbed(:category) }

      it "returns an empty array" do
        response = helper.subcompany_options_for_offer_option(offer_option, category)
        collection = helper.options_from_collection_for_select([], :name, :id)
        expect(response).to eq collection
      end
    end

    context "with an old product" do
      let(:offer_option) { create(:old_product_option) }
      let(:category) { Category.new }

      it "returns an old product subcompany" do
        response = helper.subcompany_options_for_offer_option(offer_option, category)
        subcompany_id = offer_option&.product&.subcompany&.id
        collection = helper.options_from_collection_for_select(
          [offer_option.product.subcompany], :id, :name, subcompany_id
        )
        expect(response).to eq collection
      end
    end

    context "with company" do
      let(:company) { create(:company) }
      let(:category) { create(:category) }
      let(:product) { create(:product, category: category, company: company) }
      let(:offer_option) { create(:offer_option, product: product) }
      let!(:subcompany1) do
        create(:subcompany, name: "Subcompany One", verticals: [category.vertical], company: company)
      end
      let!(:subcompany2) { create(:subcompany, name: "Subcompany Two", company: company) }

      it "returns subcompanies based on product's category" do
        response = helper.subcompany_options_for_offer_option(offer_option, category)
        collection = helper.options_from_collection_for_select(
          [subcompany1], :id, :name, offer_option&.product&.subcompany&.id
        )
        expect(response).to eq collection
      end
    end
  end

  context "ops_ui_offer_creation_asset_map" do
    context "when prepend ends with a slash" do
      before do
        allow(URI).to receive(:parse).and_return(double(read: ""))
        allow(JSON).to receive(:parse).and_return(
          "prepend" => "https://dummy.co/",
          "assets" => {
            "some-asset" => "some-asset"
          }
        )
      end

      it "removes double slash from the asset url" do
        expected_asset_map = {
          "some-asset" => "https://dummy.co/some-asset"
        }

        expect(helper.ops_ui_offer_creation_asset_map).to eq(expected_asset_map)
      end
    end

    context "when prepend does not end with a slash" do
      before do
        allow(URI).to receive(:parse).and_return(double(read: ""))
        allow(JSON).to receive(:parse).and_return(
          "prepend" => "https://dummy.co",
          "assets" => {
            "some-asset" => "some-asset"
          }
        )
      end

      it "merges domain and path" do
        expected_asset_map = {
          "some-asset" => "https://dummy.co/some-asset"
        }

        expect(helper.ops_ui_offer_creation_asset_map).to eq(expected_asset_map)
      end
    end
  end
end

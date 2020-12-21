# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/seed"

RSpec.describe Contracts::Seed do
  subject(:seeds) { described_class.new }

  it "includes Utils::Seeder in included modules" do
    expect(seeds).to be_kind_of Utils::Seeder
  end

  describe "#seed_all", :integration do
    def result_correctly_constructed(res)
      expect(res.keys.sort).to eq(%i[contracts_for_customer].sort)
      res.values.each do |element|
        expect(element).to be_kind_of Hash
        expect(element.keys).to eq(%i[contract_ids customer_id])
        expect(element.values).to be_kind_of Array
      end
    end

    def contracts_created_correctly(res)
      res.values.flatten.each do |value|
        contract_correctly_created(value[:contract_ids], value[:customer_id])
      end
    end

    def contract_correctly_created(ids, mandate_id)
      product_ids = Product.where(id: ids).pluck(:id).uniq.sort
      expect(product_ids).to eq(ids.sort)
    end

    it "creates a single product when no number passed to it" do
      size = 1
      expect {
        result = seeds.seed_all
        result_correctly_constructed(result)
        contracts_created_correctly(result)
      }.to change(Product, :count).by(size)
    end

    it "creates number of products for each customer_id when that a number and customer_id passed to it" do
      size = 2
      customers = create_list(:customer, 2)
      customers.map(&:id).each do |customer_id|
        expect {
          result = seeds.seed_all(size, customer_id)
          result_correctly_constructed(result)
          contracts_created_correctly(result)
        }.to change(Product, :count).by(size)
      end
    end
  end

  describe "#create_advised_contract_for_customer", :integration do
    it "creates a single advice for contract" do
      size = 1
      expect {
        seeds.create_advised_contract_for_customer(size, nil)
      }.to change(Interaction::Advice, :count).by(size)
    end
  end

  describe "#create_dummy_plans_for_umbrella_categories", :integration do
    let!(:category) { create(:category) }
    let!(:umbrella_category1) do
      create(:umbrella_category, vertical: vertical, included_category_ids: [create(:category).id])
    end
    let!(:umbrella_category2) do
      create(:umbrella_category, vertical: vertical, included_category_ids: [create(:category).id])
    end
    let!(:umbrella_category3) do
      create(:umbrella_category, vertical: vertical2, included_category_ids: [create(:category).id])
    end
    let!(:vertical) { create(:vertical) }
    let!(:vertical2) { create(:vertical) }
    let!(:company1) { create(:company) }
    let!(:company2) { create(:company) }
    let!(:company3) { create(:company) }
    let!(:subcompany1) { create(:subcompany, verticals: [vertical], company: company1) }
    let!(:subcompany2) { create(:subcompany, verticals: [vertical], company: company2) }
    let!(:subcompany3) { create(:subcompany, verticals: [vertical2], company: company3) }

    it "creates plans" do
      expect {
        seeds.create_dummy_plans_for_umbrella_categories
      }.to change(Plan, :count).by(5)

      expect(umbrella_category1.plans.count).to eq 2
      umbrella1_plans_names = umbrella_category1.plans.map(&:name)
      expect(umbrella1_plans_names).to include "#{umbrella_category1.name} #{company1.name}"
      expect(umbrella1_plans_names).to include "#{umbrella_category1.name} #{company2.name}"

      expect(umbrella_category2.plans.count).to eq 2
      umbrella2_plans_names = umbrella_category2.plans.map(&:name)
      expect(umbrella2_plans_names).to include "#{umbrella_category2.name} #{company1.name}"
      expect(umbrella2_plans_names).to include "#{umbrella_category2.name} #{company2.name}"

      expect(umbrella_category3.plans.count).to eq 1
      expect(umbrella_category3.plans.first.name).to eq "#{umbrella_category3.name} #{company3.name}"
    end
  end
end

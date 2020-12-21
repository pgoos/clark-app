# frozen_string_literal: true

require "rails_helper"
require "composites/customer/seed"

RSpec.describe Customer::Seed do
  subject(:seeds) { described_class.new }

  it "includes Utils::Seeder in included modules" do
    expect(seeds).to be_kind_of Utils::Seeder
  end

  describe "#seed_all", :integration do
    def result_correctly_constructed(res)
      expect(res.keys.sort).to eq(%i[prospects self_service_customers mandate_customers].sort)
      res.values.each do |element|
        expect(element).to be_kind_of Hash
        expect(element.keys).to eq([:mandate_ids])
        expect(element.values).to be_kind_of Array
      end
    end

    def customers_created_correctly(res)
      res.each do |key, value|
        clark2_state = case key
                       when :prospects
                         "prospect"
                       when :self_service_customers
                         "self_service"
                       when :mandate_customers
                         "mandate_customer"
                       end
        customer_correctly_created(value[:mandate_ids], clark2_state)
      end
    end

    def customer_correctly_created(ids, clark_state)
      mandates = Mandate.where(id: ids, customer_state: clark_state)
      expect(mandates.map(&:id).sort).to eq(ids.sort)
      mandates.each do |mandate|
        expect(mandate.email).to match(clark_state.gsub("_", "-"))
      end
    end

    it "creates a single customer of each type when no number passed to it" do
      size = 1
      expect {
        result = seeds.seed_all
        result_correctly_constructed(result)
        customers_created_correctly(result)
      }.to change(Mandate, :count).by(size * 3)
    end

    it "creates number of customer of each type when that number passed to it" do
      size = 2
      expect {
        result = seeds.seed_all(size)
        result_correctly_constructed(result)
        customers_created_correctly(result)
      }.to change(Mandate, :count).by(size * 3)
    end
  end
end

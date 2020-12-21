# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::PartnerProducts do

  context "#get_product_id_from_params" do
    it "should be able to find the correct product id for assona" do
      p_id = "3226"
      source = "assona"
      params = {"p_id" => p_id, "utm_source" => source}
      expect(described_class.new(source).get_product_id_from_params(params)).to eq("3226")
    end

    it "should not be able to find the wrong product id for assona" do
      p_id = "1"
      source = "assona"
      params = {"p_id" => p_id, "utm_source" => source}
      expect(described_class.new(source).get_product_id_from_params(params)).to eq(nil)
    end

    it "should not be able to find the correct product id if source is not assona" do
      p_id = "3226"
      source = "not_assona"
      params = {"p_id" => p_id, "utm_source" => source}
      expect(described_class.new(source).get_product_id_from_params(params)).to eq(nil)
    end
  end

  context "#get_partner_products(mandate)" do
    it "should return [], if no user or lead is given" do
      dangling_mandate = FactoryBot.build_stubbed(:mandate, user: nil, lead: nil)
      expect(described_class.get_partner_products(dangling_mandate)).to eq([])
    end

    it "should return [<product>], if given" do
      expected_partner_products = [
        {"id" => "3226", "partner" => "assona"}
      ]

      source_data = {
        "adjust"           => {"network" => "assona"},
        "partner_products" => expected_partner_products
      }
      user                    = FactoryBot.build_stubbed(:user, source_data: source_data)
      mandate_with_product_id = FactoryBot.build_stubbed(:mandate, user: user)

      actual = described_class.get_partner_products(mandate_with_product_id)
      expect(actual).to eq(expected_partner_products)
    end
  end
end

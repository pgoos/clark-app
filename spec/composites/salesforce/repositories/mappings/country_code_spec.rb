# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/mappings/country_code"

RSpec.describe Salesforce::Repositories::Mappings::CountryCode do
  describe ".entity_value" do
    it "returns correct value" do
      mandate = build(:mandate, :accepted)
      expect(described_class.entity_value(mandate)).to eq "de"
    end

    it "returns nil" do
      expect(described_class.entity_value(nil)).to be_nil
    end
  end
end

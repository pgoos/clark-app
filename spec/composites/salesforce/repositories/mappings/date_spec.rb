# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/mappings/date"

RSpec.describe Salesforce::Repositories::Mappings::Date do
  describe ".entity_value" do
    it "returns correct string date" do
      date = Date.current
      expect(described_class.entity_value(date)).to eq date.strftime("%Y-%m-%d")
    end

    it "returns nil" do
      expect(described_class.entity_value(nil)).to eq nil
    end
  end
end

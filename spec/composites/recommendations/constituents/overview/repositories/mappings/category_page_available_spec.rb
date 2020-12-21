# frozen_string_literal: true

require "spec_helper"
require "composites/recommendations/constituents/overview/repositories/mappings/category_page_available"

RSpec.describe Recommendations::Constituents::Overview::Repositories::Mappings::CategoryPageAvailable do
  describe ".entity_value" do
    let(:mapper) { described_class }

    context "when value is 'true'" do
      it "returns true" do
        expect(mapper.entity_value("true")).to be_truthy
      end
    end

    context "when value is true" do
      it "returns true" do
        expect(mapper.entity_value(true)).to be_truthy
      end
    end

    context "when value is 'false'" do
      it "returns false" do
        expect(mapper.entity_value("false")).to be_falsey
      end
    end

    context "when value is false" do
      it "returns false" do
        expect(mapper.entity_value(false)).to be_falsey
      end
    end
  end
end

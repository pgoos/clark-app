# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/mappings/home24_data"

RSpec.describe Home24::Repositories::Mappings::Home24Data do
  include_context "home24 with order"

  describe ".entity_value" do
    let(:order_number) { home24_order_number }
    let(:loyalty) { { "home24" => home24_data } }
    let(:home24_data) { { "order_number" => order_number } }

    context "when loyalty has home24_data" do
      it "returns home24 data`" do
        expect(described_class.entity_value(loyalty)).to eq(home24_data)
      end
    end

    context "when loyalty does not has data for home24" do
      it "returns a hash" do
        expect(described_class.entity_value({})).to eq({})
      end
    end
  end
end

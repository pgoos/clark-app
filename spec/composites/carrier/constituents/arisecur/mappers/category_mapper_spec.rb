# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/mappers/category_mapper"

RSpec.describe Carrier::Constituents::Arisecur::Mappers::CategoryMapper do
  let(:mapper) { described_class.new(category_name) }

  describe "#arisecur_ident" do
    before { allow(mapper).to receive(:content).and_return([{ "clarkName" => "test", "arisecurIdent" => "A123" }]) }

    context "when category exists in mapping" do
      let(:category_name) { "test" }

      it "should return instance of fake category mapper in test env" do
        expect(mapper.arisecur_ident).to eq "A123"
      end
    end

    context "when category does not exist in mapping" do
      let(:category_name) { "empty" }

      it "should return instance of fake category mapper in test env" do
        expect { mapper.arisecur_ident }
          .to raise_error Carrier::Constituents::Arisecur::Mappers::CategoryDoesNotExist
      end
    end
  end
end

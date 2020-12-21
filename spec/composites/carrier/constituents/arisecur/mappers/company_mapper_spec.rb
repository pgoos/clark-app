# frozen_string_literal: true

require "rails_helper"
require "composites/carrier/constituents/arisecur/mappers/company_mapper"

RSpec.describe Carrier::Constituents::Arisecur::Mappers::CompanyMapper do
  let(:mapper) { described_class.new(company_name) }

  describe "#arisecur_ident" do
    before { allow(mapper).to receive(:content).and_return([{ "clarkName" => "test", "arisecurIdent" => "A123" }]) }

    context "when company exists in mapping" do
      let(:company_name) { "test" }

      it "should return instance of fake company mapper in test env" do
        expect(mapper.arisecur_ident).to eq "A123"
      end
    end

    context "when company does not exist in mapping" do
      let(:company_name) { "empty" }

      it "should return instance of fake company mapper in test env" do
        expect { mapper.arisecur_ident }
          .to raise_error Carrier::Constituents::Arisecur::Mappers::CompanyDoesNotExist
      end
    end
  end
end

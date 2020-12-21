# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::RetirementProcess, :integration, :retirement, :clark_with_master_data do
  include_context "retirement integration fixtures"

  context "RetirementProcess with Paul Pension Mandate" do
    before(:each) do
      @mandate = Mandate.last
    end

    it "checks that deathies are there" do
      expect(Retirement::Deathy.count).to eq(124)
    end

    context ".mandate_equity_products" do
      it "returns a product" do
        expect(described_class.mandate_equity_products(@mandate).count).to eq(1)
      end
    end
  end
end

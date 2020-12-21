# frozen_string_literal: true

RSpec.shared_examples "shared cockpit totals behaviour" do
  let(:products) do
    [
      build_stubbed(:product, premium_price: 100, premium_period: "month"),
      build_stubbed(:product, premium_price: 216, premium_period: "year"),
      build_stubbed(:product, premium_price: 500, premium_period: "once")
    ]
  end

  describe "#products_yearly_total" do
    it "summarizes all yearly premium prices" do
      expect(subject.products_yearly(products)).to be_a Money
      expect(subject.products_yearly(products).to_i).to eq 1416
    end

    context "when none products available" do
      it "returns zero" do
        expect(subject.products_yearly([])).to be_a Money
        expect(subject.products_yearly([]).to_i).to eq 0
      end
    end

    it "excludes products which have start date in the future" do
      products = [
        build_stubbed(:product, premium_price: 100, premium_period: "month", contract_started_at: Time.zone.now),
        build_stubbed(:product, premium_price: 216, premium_period: "year", contract_started_at: Time.zone.tomorrow)
      ]
      expect(subject.products_yearly(products)).to be_a Money
      expect(subject.products_yearly(products).to_i).to eq 1200
    end

    it "excludes products which contract has already ended" do
      products = [
        build_stubbed(:product, premium_price: 100, premium_period: "month", contract_ended_at: Time.zone.tomorrow),
        build_stubbed(:product, premium_price: 216, premium_period: "year", contract_ended_at: 1.day.ago)
      ]
      expect(subject.products_yearly(products)).to be_a Money
      expect(subject.products_yearly(products).to_i).to eq 1200
    end
  end

  describe "#products_monthly_total" do
    it "summarizes all monthly premium prices" do
      expect(subject.products_monthly(products)).to be_a Money
      expect(subject.products_monthly(products).to_i).to eq 118
    end

    context "when none products available" do
      it "returns zero" do
        expect(subject.products_monthly([])).to be_a Money
        expect(subject.products_monthly([]).to_i).to eq 0
      end
    end

    it "excludes products which have start date in the future" do
      products = [
        build_stubbed(:product, premium_price: 100, premium_period: "month", contract_started_at: Time.zone.tomorrow),
        build_stubbed(:product, premium_price: 216, premium_period: "year", contract_started_at: 1.day.ago)
      ]
      expect(subject.products_monthly(products)).to be_a Money
      expect(subject.products_monthly(products).to_i).to eq 18
    end

    it "excludes products which contract has already ended" do
      products = [
        build_stubbed(:product, premium_price: 100, premium_period: "month", contract_ended_at: Time.zone.tomorrow),
        build_stubbed(:product, premium_price: 216, premium_period: "year", contract_ended_at: 1.day.ago)
      ]
      expect(subject.products_yearly(products)).to be_a Money
      expect(subject.products_yearly(products).to_i).to eq 1200
    end
  end
end

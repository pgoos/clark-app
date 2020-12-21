# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::NewContractBegin do
  subject(:begin_date) do
    described_class.new(old_product: old_product, customer_wish: customer_wish)
  end

  let(:t0) { Time.zone.parse("2017-09-04 12:00:00") }
  let(:old_product) { object_double Product.new, contract_ended_at: old_contract_end }
  let(:customer_wish) { t0.advance(days: 2) }
  let(:old_contract_end) { nil }

  before do
    Timecop.freeze(t0)
  end

  after do
    Timecop.return
  end

  context "when instantiated from opportunity" do
    let(:opportunity) do
      n_instance_double(Opportunity, "opportunity", old_product: old_product, preferred_insurance_start_date: nil)
    end
    let(:old_product) { n_instance_double(Product, "old_product") }

    it "should be instantiated with the old product" do
      calculator = described_class.from_opportunity(opportunity)
      expect(calculator.old_product).to eq(old_product)
    end

    context "and opportunity has a preferred_insurance_start_date" do
      let(:future_date) { (t0 + 2.days).strftime("%d.%m.%Y") }
      let(:opportunity) do
        n_instance_double(Opportunity, "opportunity", old_product: nil, preferred_insurance_start_date: future_date)
      end

      it "returns the preferred_insurance_start_date as customer wish begin date" do
        calculator = described_class.from_opportunity(opportunity)
        expect(calculator.calculate).to eq(t0 + 2.days)
      end
    end
  end

  context "when old product and customer wish date are empty" do
    let(:customer_wish) { nil }
    let(:old_product)   { nil }

    it "returns next date" do
      expect(begin_date.calculate).to eq t0.advance(days: 1).noon
    end
  end

  context "when old product end date is in the future" do
    let(:customer_wish) { t0 + 1.year }

    context "when product is KFZ" do
      before { allow(old_product).to receive(:kfz?).and_return true }

      context "when end date is more than 1 month in future" do
        let(:old_contract_end) { t0.advance(months: 1, days: 1) }

        it "returns end date of old product" do
          expect(begin_date.calculate).to eq old_contract_end.noon
        end
      end

      context "when end date is less than 1 month in future" do
        let(:old_contract_end) { t0.advance(days: 27) }

        it "adds one year to end date of old product" do
          expect(begin_date.calculate).to eq old_contract_end.advance(years: 1).noon
        end
      end
    end

    context "when product is not KFZ" do
      before { allow(old_product).to receive(:kfz?).and_return false }

      context "when end date is more than 3 month in future" do
        let(:old_contract_end) { t0.advance(months: 3, days: 1) }

        it "returns end date of old product" do
          begin_date.calculate
          expect(begin_date.calculate).to eq old_contract_end.noon
        end
      end

      context "when end date is less than 3 month in future" do
        let(:old_contract_end) { t0.advance(months: 2, days: 27) }

        it "adds one year to end date of old product" do
          expect(begin_date.calculate).to eq old_contract_end.advance(years: 1).noon
        end
      end
    end
  end

  context "when old product date is empty or in the past" do
    let(:old_contract_end) { t0 - 1.day }

    context "with customer wish date" do
      context "when its in the future" do
        it "returns customer with date" do
          expect(begin_date.calculate).to eq customer_wish.noon
        end
      end

      context "when its in the past" do
        let(:customer_wish) { t0 - 1.day }

        it "returns tomorrow as begin date" do
          expect(begin_date.calculate).to eq t0.advance(days: 1).noon
        end
      end
    end

    context "without cusomer wish date" do
      let(:customer_wish) { nil }

      it "returns tomorrow as begin date" do
        expect(begin_date.calculate).to eq t0.advance(days: 1).noon
      end
    end
  end
end

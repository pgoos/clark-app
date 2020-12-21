# frozen_string_literal: true

require "spec_helper"

require "ostruct"
require "presenters/commission_rate_presenter"

describe CommissionRatePresenter, type: :presenter do
  describe "#present" do
    let(:view_model) { described_class.present(commission_rate) }

    context "when comission rate has correct values" do
      let(:commission_rate) do
        OpenStruct.new(
          rate: 1.84,
          deduction_reserve_sales: 10,
          deduction_fidelity_sales: 0,
        )
      end

      it "return a view model" do
        expect(view_model).to be_kind_of(CommissionRatePresenter::CommissionRateViewModel)
      end

      it "return correct values" do
        expect(view_model.rate).to be(1.84)
        expect(view_model.deduction_reserve_sales).to be(10)
        expect(view_model.deduction_fidelity_sales).to be(0)
      end
    end

    context "when comission rate has no value" do
      let(:commission_rate) { nil }

      it "return a formatted value" do
        expect(view_model.rate).to be("—")
        expect(view_model.deduction_reserve_sales).to be("—")
        expect(view_model.deduction_fidelity_sales).to be("—")
      end
    end
  end
end

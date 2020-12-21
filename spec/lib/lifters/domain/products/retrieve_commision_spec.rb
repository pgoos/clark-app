# frozen_string_literal: true

require "spec_helper"
require "structs/commission_rate"
require "lifters/domain/products/retrieve_commission"
require "presenters/commission_rate_presenter"

RSpec.describe Domain::Products::RetrieveCommission do
  let(:commissions_repository) { class_double("CommissionRatesRepository") }
  let(:service) do
    described_class.new(
      commissions_repository,
      CommissionRatePresenter
    )
  end

  describe "call" do
    let(:struct) do
      Structs::CommissionRate.new(
        pool: "FondsFinanz",
        rate: 1.84,
        contract_sales_channel: "FondsFinanz",
        deduction_reserve_sales: 10.0,
        deduction_fidelity_sales: 0.0,
      )
    end

    before do
      allow(commissions_repository).to receive(:find_by).and_return(struct)
    end

    it "returns a view model" do
      view_model = service.call({})
      expect(view_model).to be_kind_of(CommissionRatePresenter::CommissionRateViewModel)
    end

    it "has formatted values" do
      view_model = service.call({})
      expect(view_model.rate).to be(1.84)
      expect(view_model.deduction_reserve_sales).to be(10.0)
      expect(view_model.deduction_fidelity_sales).to be(0.0)
    end
  end
end

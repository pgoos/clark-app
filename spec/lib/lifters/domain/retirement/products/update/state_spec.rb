# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Products::Update::State do
  subject(:update) { described_class.new product }

  let(:product) do
    object_double Retirement::Product.new,
                  update!: true,
                  customer_forecast!: true,
                  details_saved: true
  end

  it "changes forecast value to 'customer'" do
    expect(product).to receive(:customer_forecast!)
    update.(surplus_retirement_income: 1_000)
  end

  it "updates the product" do
    expect(product).to receive(:update!).with(surplus_retirement_income: 1_000)
    update.(surplus_retirement_income: 1_000)
  end

  it "updates state of the retirement product" do
    expect(product).to receive(:details_saved)
    update.(surplus_retirement_income: 1_000)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  # Setup

  let(:product) { create(:product, inquiry: create(:inquiry)) }
  subject { product }

  it { expect(subject).to belong_to(:inquiry) }
  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:plan) }

  it { expect(subject).to have_one(:company).through(:plan) }
  it { expect(subject).to have_one(:subcompany).through(:plan) }
  it { expect(subject).to have_one(:category).through(:plan) }
  it { expect(subject).to have_many(:loyalty_bookings) }
  it { expect(subject).to have_one(:retirement_product) }

  it { expect(subject).to have_many(:documents).dependent(:destroy) }
  it { expect(subject).to have_many(:follow_ups).dependent(:destroy) }
  it { expect(subject).to have_many(:interactions).dependent(:destroy) }
  it { expect(subject).to have_many(:product_partner_data).dependent(:destroy) }

  it "does not set the company_id on the product directly", :legacy do
    plan    = create(:plan)
    product = create(:product, plan: plan)

    # There used to be a company_id field on products directly, if this field is
    # still there, it should be set to nil
    product_company_id_value = begin
                                 product.read_attribute(:company_id)
                               rescue
                                 nil
                               end
    expect(product_company_id_value).to be_nil

    # The company should still be reachable through the plan
    expect(product.company).to eq(plan.company)
  end
end

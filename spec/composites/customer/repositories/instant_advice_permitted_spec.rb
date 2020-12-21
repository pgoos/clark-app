# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find"

RSpec.describe Customer::Repositories::InstantAdvicePermitted, :integration do
  let(:gkv_product) { create(:product_gkv) }
  let(:gkv_advice_while_ia_on) do
    create(:advice, :created_while_instant_advice_is_on, product: gkv_product, mandate: gkv_product.mandate)
  end
  let(:gkv_advice_while_ia_off) do
    create(:advice, :created_by_robo_advisor, product: gkv_product, mandate: gkv_product.mandate)
  end
  let(:product) { create(:product) }
  let(:advice) { create(:advice, product: product, mandate: product.mandate) }

  before do
    allow(Features).to receive(:active?)
    allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(true)
  end

  it "returns false when customer has non gkv advices" do
    expect(subject).not_to be_permitted(customer_id: advice.mandate_id)
  end

  it "returns false when customer has gkv advices created before switching instant advice ON" do
    expect(subject).not_to be_permitted(customer_id: gkv_advice_while_ia_off.mandate_id)
  end

  it "returns true when customer has gkv advices created after switching instant advice ON" do
    expect(subject).to be_permitted(customer_id: gkv_advice_while_ia_on.mandate_id)
  end

  it "returns true when customer has no advices at all" do
    expect(subject).to be_permitted(customer_id: product.mandate_id)
  end

  it "return false when feature switch is OFF" do
    allow(Features).to receive(:active?).with(Features::INSTANT_ADVICE).and_return(false)
    expect(subject).not_to be_permitted(customer_id: product.mandate_id)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::ProductAdviceInvalidated do
  let(:advice) { double(:advice) }
  let(:product) { double :product }

  before do
    allow(product).to receive(:last_advice).and_return(advice)
  end

  it "sets advice invalid" do
    expect(advice).to receive(:update!).with(valid: false)
    described_class.(product)
  end
end

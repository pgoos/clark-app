# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find"

RSpec.describe Customer::Interactors::InstantAdvicePermitted, :integration do
  let(:instant_advice_permitted_repo) { double :instant_advice_permitted_repo }
  let(:customer) { create(:customer) }

  it "successes when repo respond with true" do
    allow(instant_advice_permitted_repo).to receive(:permitted?).and_return(true)
    result = described_class.new(instant_advice_permitted_repo: instant_advice_permitted_repo).call(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
  end

  it "fails when repo respond with false" do
    allow(instant_advice_permitted_repo).to receive(:permitted?).and_return(false)
    result = described_class.new(instant_advice_permitted_repo: instant_advice_permitted_repo).call(customer.id)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_failure
  end
end

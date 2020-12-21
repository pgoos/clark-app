# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InquiryCategories::InquiryCategoryCompleted do
  let(:inquiry_category) { double(:inquiry_category, id: 1) }

  before do
    allow(::Payback).to receive(:mark_transaction_to_unlock).and_return(double("Utils::Interactor::Result"))
  end

  it "calls the public method on the Payback composite" do
    expect(::Payback).to receive(:mark_transaction_to_unlock).with(inquiry_category.id)

    described_class.call(inquiry_category)
  end
end

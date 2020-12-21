# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InquiryCategories::InquiryCategoryDeleted do
  let(:inquiry_category_id) { 1 }

  before do
    allow(::Payback).to receive(:handle_cancelled_inquiry_category).and_return(double("Utils::Interactor::Result"))
  end

  it "calls the public method on the Payback composite" do
    expect(::Payback).to receive(:handle_cancelled_inquiry_category).with(inquiry_category_id)

    described_class.call(inquiry_category_id)
  end
end

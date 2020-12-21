# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Statistics::Goodbye do
  subject { described_class.new(mandate: mandate) }

  let(:mandate) { double(Mandate) }

  let(:offer) do
    offer = double(Offer)
    allow(offer).to receive_message_chain("category.name")
      .and_return("OfferCategory")
    offer
  end

  let(:inquiry_category) do
    inquiry_category = double(InquiryCategory)
    allow(inquiry_category).to receive_message_chain("category.name")
      .and_return("InquiryCategory")
    inquiry_category
  end

  before do
    allow_any_instance_of(Statistics::User::OffersRepository).to receive(:requested)
      .and_return([offer])

    allow_any_instance_of(Statistics::User::OffersRepository).to receive(:accepted)
      .and_return([offer])

    allow_any_instance_of(Statistics::User::InquiriesRepository).to receive(:categories)
      .and_return([inquiry_category])
  end

  describe "#all" do
    it "returns a representation" do
      expect(subject.all).to eq(
        offers_accepted: %w[OfferCategory],
        offers_requested: %w[OfferCategory],
        products_uploaded: %w[InquiryCategory]
      )
    end
  end
end

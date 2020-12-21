# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Statistics::Greeting do
  subject { described_class.new(mandate: mandate) }

  let(:mandate) { double(Mandate) }

  let(:product) do
    product = double(Product)
    allow(product).to receive_message_chain("category.name")
      .and_return("ProductCategory")
    product
  end

  let(:offer) do
    offer = double(Offer)
    allow(offer).to receive_message_chain("category.name")
      .and_return("OfferCategory")
    offer
  end

  let(:advice) do
    advice = double(Interaction::Advice)
    allow(advice).to receive_message_chain("product.category.name")
      .and_return("AdviceCategory")
    advice
  end

  before do
    allow_any_instance_of(Statistics::User::ProductsRepository).to receive(:entered_into_status)
      .and_return([product])

    allow_any_instance_of(Statistics::User::OffersRepository).to receive(:created_since)
      .and_return([offer])

    allow_any_instance_of(Statistics::User::AdvicesRepository).to receive(:created_on_products)
      .and_return([advice])

    allow(mandate).to receive(:info).and_return(OpenStruct.new("last_visited_at" => DateTime.current))
  end

  describe "#all" do
    it "returns a representation" do
      expect(subject.all).to eq(
        products: %w[ProductCategory],
        offers: %w[OfferCategory],
        advices: %w[AdviceCategory]
      )
    end
  end
end

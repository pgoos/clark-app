# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Offer do
  include ActionView::Helpers::NumberHelper

  subject { described_class }

  let(:offer) { FactoryBot.build_stubbed(:offer) }

  it { is_expected.to expose(:cheapest_option_price).of(offer).as(Hash).with_value({}) }
  it { is_expected.to expose(:form_of_payment).of(offer).with_nil_value }

  context "offer options", :integration do
    let(:cheapest_option) { create(:price_option, :cheap_product, recommended: true) }
    let(:offer_with_options) do
      # factory girl cannot properly handle active record with nested objects when using
      # 'build_stubbed'. Due to this, we need to really create the objects.
      create(
        :offer,
        offer_options: [
          create(:offer_option),
          create(:offer_option),
          cheapest_option
        ]
      )
    end

    it do
      raw_price = cheapest_option.product.premium_price.to_f
      is_expected.to expose(:cheapest_option_price).of(offer_with_options)
        .as(Hash)
        .with_value(
          value: number_with_precision(raw_price, precision: 2),
          currency: "€"
        )
    end

    it do
      period = cheapest_option.product.premium_period
      is_expected.to expose(:form_of_payment).of(offer_with_options)
        .as(ValueTypes::FormOfPayment)
        .with_value(ValueTypes::FormOfPayment.from_attribute_domain(period))
    end
  end
end

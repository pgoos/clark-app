# frozen_string_literal: true

require "rails_helper"
require "composites/offers/constituents/manual_creation/repositories/offer_option_repository"

RSpec.describe Offers::Constituents::ManualCreation::Repositories::OfferOptionRepository, :integration do
  subject { described_class.new }

  describe "#find_by_ids" do
    let(:category) { create(:category_gkv) }
    let!(:product) do
      create(:product,
        contract_started_at: 1.week.from_now.beginning_of_day,
        contract_ended_at:   2.weeks.from_now.beginning_of_day,
        category:            category,
        documents:           create_list(:document, 2),
        coverages:           {
          "text_htkrbsfrhrknnng_d3a6f8" => {
            "text" => "ja",
            "type" => "Text"
          }
        })
    end
    let(:offer_options) { create_list(:cover_option, 2, product: product) }

    it "returns offer_option entity" do
      result = subject.find_by_ids(offer_options.map(&:id))
      expect(result.count).to eq 2

      option = result.first
      expect(option.offer_option_id).to eq offer_options[0].id
      expect(option.premium_price_cents).to eq product.premium_price_cents
      expect(option.premium_price_currency).to eq product.premium_price_currency
      expect(option.premium_period).to eq product.premium_period
      expect(option.contract_start).to eq product.contract_started_at
      expect(option.contract_end).to eq product.contract_ended_at
      expect(option.option_type).to eq offer_options[0].option_type
      expect(option.contract_id).to eq offer_options[0].product_id
      expect(option.plan_ident).to eq offer_options[0].plan_ident

      expect(option.documents.count).to eq 2
      expect(option.documents.first).to be_a(Offers::Constituents::ManualCreation::Entities::Document)

      expect(option.coverages["text_htkrbsfrhrknnng_d3a6f8"]).to be_a(ValueTypes::Text)
      expect(option.coverages["text_htkrbsfrhrknnng_d3a6f8"].text).to eq "ja"
    end
  end
end

# == Schema Information
#
# Table name: offer_options
#
#  id          :integer          not null, primary key
#  offer_id    :integer
#  product_id  :integer
#  recommended :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  option_type :string
#

FactoryBot.define do
  factory :offer_option do
    product factory: :product, state: 'offered', mandate: nil
    recommended { false }
    option_type { OfferOption.option_types[:top_cover_and_price] }

    factory :price_option do
      option_type { OfferOption.option_types[:top_price] }
    end

    trait :cheap_product do
      association :product, :cheap_product, state: 'offered', mandate: nil
    end

    factory :cover_option do
      option_type { OfferOption.option_types[:top_cover] }
    end

    factory :old_product_option do
      product factory: :product, state: 'details_available'
      option_type { OfferOption.option_types[:old_product] }
    end
  end
end

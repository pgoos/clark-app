# frozen_string_literal: true

FactoryBot.define do
  trait :home24 do
    loyalty { { home24: {} } }
  end

  trait :home24_with_data do
    transient do
      order_number { "10187654321" }
    end

    loyalty { { home24: { "order_number" => order_number } } }
  end

  trait(:with_free_home24_product) do
    after(:create) do |mandate|
      free_product_plan = FactoryBot.create(:plan,
                                            ident: Home24::Entities::Product::FREE_PLAN_IDENT)
      free_product = FactoryBot.build(:product,
                                      state: Home24::Entities::Product::ACTIVE_STATES.first,
                                      plan_id: free_product_plan.id)
      mandate.products << free_product
      mandate.save
    end
  end
end

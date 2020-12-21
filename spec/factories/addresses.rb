# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    street       { "Thingamabob" }
    house_number { "2332" }
    zipcode      { "12345" }
    city         { "Clark Town" }
    country_code { "DE" }
    active
    accepted
    insurers_notified { true }

    trait :active do
      active { true }
    end

    trait :accepted do
      accepted { true }
    end

    trait :inactive do
      active { false }
    end
  end

  factory :invalid_address, class: "Address" do
    street       {  }
    house_number {  }
    zipcode      {  }
    city         {  }
    country_code {  }
  end
end

require 'securerandom'

FactoryBot.define do
  factory :promotion_code do
    code { SecureRandom.hex(4) }
    lead { nil }
  end

end

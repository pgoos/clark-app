FactoryBot.define do
  factory :ahoy_message, class: 'Ahoy::Message' do
    token { SecureRandom.urlsafe_base64(32).gsub(/[\-_]/, "").first(32) }
  end
end

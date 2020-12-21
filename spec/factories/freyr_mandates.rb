# frozen_string_literal: true

FactoryBot.define do
  trait :freyr do
    owner_ident { "n26" }
    info { { "freyr": { "migration_state": "to_migrate" } } }
  end

  trait :freyr_with_data do
    transient do
      migration_token { SecureRandom.alphanumeric(16) }
      migration_state { "to_migrate" }
      token_generated_at { Time.zone.now }
    end

    owner_ident { "n26" }
    info {
      { "freyr": { "migration_state": migration_state,
                   "migration_token": migration_token,
                   "token_generated_at": token_generated_at } }
    }
  end
end

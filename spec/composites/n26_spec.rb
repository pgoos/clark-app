# frozen_string_literal: true

require "rails_helper"
require "composites/n26"

RSpec.describe N26, :integration do
  let(:token) { SecureRandom.alphanumeric(16) }
  let!(:customer) do
    create(
      :mandate,
      :owned_by_n26,
      info: { "freyr": { "migration_token": token } }
    )
  end

  it "finds and returns the customer with the migration token" do
    result = described_class.find_customer_by_migration_token(token)
    expect(result).to be_kind_of Utils::Interactor::Result
    expect(result).to be_successful
    expect(result.customer).to be_kind_of N26::Constituents::Freyr::Entities::Customer
    expect(result.customer.id).to eq customer.id
  end
end

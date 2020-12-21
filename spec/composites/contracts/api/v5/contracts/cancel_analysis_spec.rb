# frozen_string_literal: true

require "rails_helper"

describe "DELETE /api/contracts/:id", :integration, type: :request do
  let(:customer) { create(:customer, :self_service) }
  let(:contract) do
    create(
      :contract,
      :under_analysis,
      customer_id: customer.id
    )
  end

  before do
    login_customer(customer, scope: :user)
  end

  it do
    json_delete_v5 "/api/contracts/#{contract.id}"
    expect(response.status).to eq 204
  end
end

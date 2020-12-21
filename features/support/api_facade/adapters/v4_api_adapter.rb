# frozen_string_literal: true

# Class provides interfaces for the interaction with Clark API V4 resources
class V4APIAdapter
  # @param client [Client]
  def initialize(client)
    @client = client
  end

  # ClarkAPI::V4::Categories -------------------------------------------------------------------------------------------

  # @return [Array] required for the V2APIAdapter.add_inquiries request
  def get_active_categories # rubocop:disable Naming/AccessorMethodName
    @categories = @client.execute_http_request("get", "api/categories/active", 200)["categories"]
  end
end

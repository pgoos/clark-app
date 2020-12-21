# frozen_string_literal: true

# Class provides interface for the interaction with Clark web application
class WebAppAdapter
  # @param client [Client]
  def initialize(client)
    @client = client
  end

  def get_sign_up_cookies # rubocop:disable Naming/AccessorMethodName
    @client.execute_http_request("get", "de/signup", 302)
  end
end

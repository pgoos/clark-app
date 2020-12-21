# frozen_string_literal: true

require "faraday"
require "json"

class FakeSMTPHTTPClient
  RESOURCE_PATH = "api/emails/?to="
  def initialize(http_auth_name, http_auth_pwd, fake_smtp_server_url)
    @http_auth_name = http_auth_name
    @http_auth_pwd = http_auth_pwd
    @fake_smtp_server_url = fake_smtp_server_url
    @connection = init_connection
  end

  def init_connection
    Faraday.new(url: @fake_smtp_server_url) do |faraday|
      faraday.basic_auth(@http_auth_name, @http_auth_pwd)
      faraday.request :url_encoded # form-encode POST params
      faraday.request :retry, max: 2, exceptions: [Faraday::TimeoutError]
      faraday.request :retry, max: 2, interval: 10, exceptions: [Faraday::ConnectionFailed], methods: %i[get]
      faraday.options[:timeout] = 180
      faraday.adapter Faraday.default_adapter
    end
  end

  def execute_http_request(email)
    # Prepare and execute HTTP request
    params = { "to": email }
    resp = @connection.get(RESOURCE_PATH) { |req| req.params = params }

    # return parsed JSON if success response code is 200 else raise exception
    return JSON.parse(resp.body) if resp.status == 200
    msg = %(Request failed
            Resource path: #{RESOURCE_PATH}
            Expected status code #{200} but was #{resp.status}
            Response body: #{resp.body}
    )
    raise Net::HTTPError.new(msg, resp)
  end
end

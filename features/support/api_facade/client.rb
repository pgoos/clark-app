# frozen_string_literal: true

# Class provides some basic interfaces for the interaction with various Clark APIs
class Client
  attr_reader :connection, :session

  # @param session [Session]
  # @param api_version [String, nil] Clark API version (v2, v3, etc)
  def initialize(session, api_version=nil)
    @api_version = api_version
    @app_host = Capybara.app_host
    @connection = init_connection
    @session = session
  end

  # Method obtains cookies and csrf token from a session, executes HTTP request,
  # asserts response status code, saves cookies and returns a response body
  # @param type [String] type of HTTP request. Example: get, put, delete
  # @param url [String] resource path
  # @param expected_resp_code [Integer] expected response status code
  # @param body [Hash, nil] request payload
  # @param params [Hash, nil] query string
  # @return [Array, String, nil] response body. The method tries to convert it to JSON and return a converted result if succeed
  def execute_http_request(type, url, expected_resp_code, body: nil, params: {})
    # Prepare and execute HTTP request
    resp = @connection.method(type).call do |req|
      req.url url
      req.headers["accept"] = "application/vnd.clark-#{@api_version}+json" unless @api_version.nil?
      req.headers["content-type"] = "application/json" unless body.nil?
      req.headers["x-csrf-token"] = @session.csrf_token
      req.headers["cookie"] = load_cookies
      req.params = params unless params.empty?
      req.body = body.is_a?(Hash) ? body.to_json : body if body
    end

    # Raise exception if response status code doesn't equal to the expected
    if resp.status != expected_resp_code
      msg = %(Request failed
              Resource path: #{url}
              Expected status code #{expected_resp_code} but was #{resp.status}
              Request payload: #{body}
              Response body: #{resp.body}
      )
      raise Net::HTTPError.new(msg, resp)
    end

    # Parse set-cookie header
    parse_set_cookies_header(resp)

    # Try to parse resp body and return the result
    return nil if resp.body.nil?
    begin
      JSON.parse(resp.body)
    rescue JSON::ParserError
      resp.body
    end
  end

  private

  def init_connection
    Faraday.new(url: @app_host) do |faraday|
      if TestContextManager.instance.staging? || TestContextManager.instance.staging_2_20?
        faraday.basic_auth(TestContextManager.instance.http_auth_username,
                           TestContextManager.instance.http_auth_password)
      end

      faraday.request :url_encoded # form-encode POST params
      # faraday.response :logger # log requests and responses to $stdout
      faraday.request :retry, max: 2, exceptions: [Faraday::TimeoutError]
      faraday.request :retry, max: 2, interval: 10, exceptions: [Faraday::ConnectionFailed],
                      methods: %i[delete get head options put patch post]
      faraday.options[:timeout] = 180
      faraday.adapter Faraday.default_adapter
    end
  end

  # Method loads and returns cookies from a session
  # @return [String]
  def load_cookies
    HTTP::Cookie.cookie_value(@session.cookie_jar.cookies)
  end

  # Method loads cookies from response to a session
  def parse_set_cookies_header(resp)
    return unless resp.headers["set-cookie"]
    HTTP::Cookie.parse(resp.headers["set-cookie"], @app_host).each { |cookie| @session.cookie_jar.add(cookie) }
  end
end

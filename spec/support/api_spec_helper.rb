# frozen_string_literal: true

module ApiSpecHelper
  require_relative "api/api_v4_helper"
  require_relative "api/api_v5_helper"
  require_relative "api/api_automation_helper"
  require_relative "api/admin/api_admin_v2_helper"

  DEFAULT_CONTENT_TYPE = "application/json"

  include ApiV4Helper
  include ApiV5Helper
  include ApiAutomationHelper
  include ApiAdminV2Helper

  # Methods for Version 1 ==========================================================================
  DEFAULT_API_HEADERS_V1 = {
    "CONTENT_TYPE" => DEFAULT_CONTENT_TYPE,
    "ACCEPT"       => ClarkAPI::V1::Root::API_VERSION_HEADER
  }.freeze

  def json_response
    parsed = JSON.parse(response.body)
    return Hashie::Mash.new(parsed) if parsed.is_a?(Hash)
    return parsed.map { |i| Hashie::Mash.new(i) } if parsed.is_a?(Array)
    raise "Could not prepare the response body!"
  end

  def json_get(endpoint, query_params={}, headers={})
    get endpoint, params: query_params.to_json, headers: DEFAULT_API_HEADERS_V1.merge(headers)
  end

  def json_post(endpoint, payload_hash={}, headers={})
    post endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V1.merge(headers)
  end

  def json_patch(endpoint, payload_hash={}, headers={})
    patch endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V1.merge(headers)
  end

  def json_put(endpoint, payload_hash={}, headers={})
    put endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V1.merge(headers)
  end

  # Methods for Version 2 ==========================================================================
  DEFAULT_API_HEADERS_V2 = {
    "CONTENT_TYPE" => DEFAULT_CONTENT_TYPE,
    "ACCEPT"       => ClarkAPI::V2::Root::API_VERSION_HEADER
  }.freeze

  def json_post_v2(endpoint, payload_hash={}, headers={})
    post endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  def json_put_v2(endpoint, payload_hash={}, headers={})
    put endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  def json_get_v2(endpoint, query_params={}, headers={})
    get endpoint, params: query_params, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  def json_patch_v2(endpoint, payload_hash={}, headers={})
    patch endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  def json_delete_v2(endpoint, payload_hash={}, headers={})
    delete endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  def post_v2(endpoint, payload_hash={}, headers={})
    post endpoint, params: payload_hash, headers: DEFAULT_API_HEADERS_V2.merge(headers)
  end

  # Methods for Version 3 ==========================================================================
  DEFAULT_API_HEADERS_V3 = {
    "CONTENT_TYPE" => DEFAULT_CONTENT_TYPE,
    "ACCEPT"       => ClarkAPI::V3::Root::API_VERSION_HEADER
  }.freeze

  def json_post_v3(endpoint, payload_hash={}, headers={})
    post endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  def json_put_v3(endpoint, payload_hash={}, headers={})
    put endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  def json_get_v3(endpoint, query_params={}, headers={})
    get endpoint, params: query_params, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  def json_patch_v3(endpoint, payload_hash={}, headers={})
    patch endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  def json_delete_v3(endpoint, payload_hash={}, headers={})
    delete endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  def post_v3(endpoint, payload_hash={}, headers={})
    post endpoint, params: payload_hash, headers: DEFAULT_API_HEADERS_V3.merge(headers)
  end

  # Methods for Partners API Version ===============================================================
  DEFAULT_PARTNERS_API_HEADERS = {
    "CONTENT_TYPE" => DEFAULT_CONTENT_TYPE,
    "ACCEPT"       => ClarkAPI::Partners::Root::API_VERSION_HEADER
  }.freeze

  def generate_auth_access_token
    @client = create(:api_partner)
    @client.save_secret_key!("raw")
    @client.update_access_token_for_instance!("test")
    @access_token = @client.access_token_for_instance("test")["value"]
  end

  def partners_get(endpoint, query_params: {}, headers: {})
    get endpoint, params: query_params, headers: DEFAULT_PARTNERS_API_HEADERS.merge(headers)
  end

  def partners_post(endpoint, payload_hash: {}, headers: {}, json: true)
    params = json ? payload_hash.to_json : payload_hash
    post endpoint, params: params, headers: DEFAULT_PARTNERS_API_HEADERS.merge(headers)
  end

  def partners_put(endpoint, payload_hash: {}, headers: {})
    put endpoint, params: payload_hash.to_json, headers: DEFAULT_PARTNERS_API_HEADERS.merge(headers)
  end

  def partners_patch(endpoint, payload_hash: {}, headers: {})
    patch endpoint, params: payload_hash, headers: DEFAULT_PARTNERS_API_HEADERS.merge(headers)
  end

  def partners_delete(endpoint, payload_hash: {}, headers: {})
    delete endpoint, params: payload_hash, headers: DEFAULT_PARTNERS_API_HEADERS.merge(headers)
  end

  # HTTP expectations:

  def expect_ok
    expect_code("200")
  end

  def expect_not_found
    expect_code("404")
  end

  def expect_method_not_allowed
    expect_code("405")
  end

  private

  # Let's try to not use the explicit codes, but use readable methods as 'expect_ok'. So keep this one private.
  def expect_code(code)
    expect(response.code).to eq(code), -> { error_message(expected_code: code) }
  end

  def error_message(expected_code:)
    actual_code = response.code
    resolved_expected = Rack::Utils::HTTP_STATUS_CODES[expected_code.to_i]
    resolved_actual = Rack::Utils::HTTP_STATUS_CODES[actual_code.to_i]
    <<~ERROR_MESSAGE
      Expected #{expected_code}/#{resolved_expected}, got #{actual_code}/#{resolved_actual}:
      #{JSON.pretty_generate(json_response)}"
    ERROR_MESSAGE
  end
end

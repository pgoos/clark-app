# frozen_string_literal: true

module ApiSpecHelper
  module ApiV4Helper
    DEFAULT_API_HEADERS_V4 = {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => ClarkAPI::V4::Root::API_VERSION_HEADER
    }.freeze

    def json_post_v4(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def post_v4(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def json_put_v4(endpoint, payload_hash={}, headers={})
      put endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def json_get_v4(endpoint, query_params={}, headers={})
      get endpoint, params: query_params, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def json_patch_v4(endpoint, payload_hash={}, headers={})
      patch endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def json_delete_v4(endpoint, payload_hash={}, headers={})
      delete endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V4.merge(headers)
    end

    def json_response
      response.body.present? && JSON.parse(response.body)
    end
  end
end

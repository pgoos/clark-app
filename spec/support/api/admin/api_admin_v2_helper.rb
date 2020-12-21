# frozen_string_literal: true

module ApiSpecHelper
  module ApiAdminV2Helper
    API_HEADERS_ADMIN_V2 = {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT"       => ClarkAPI::Admin::V2::Root::API_VERSION_HEADER
    }.freeze

    def json_admin_post_v2(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash.to_json, headers: API_HEADERS_ADMIN_V2.merge(headers)
    end

    def json_admin_put_v2(endpoint, payload_hash={}, headers={})
      put endpoint, params: payload_hash.to_json, headers: API_HEADERS_ADMIN_V2.merge(headers)
    end

    def json_admin_get_v2(endpoint, query_params={}, headers={})
      get endpoint, params: query_params, headers: API_HEADERS_ADMIN_V2.merge(headers)
    end

    def json_admin_patch_v2(endpoint, payload_hash={}, headers={})
      patch endpoint, params: payload_hash.to_json, headers: API_HEADERS_ADMIN_V2.merge(headers)
    end

    def json_admin_delete_v2(endpoint, payload_hash={}, headers={})
      delete endpoint, params: payload_hash.to_json, headers: API_HEADERS_ADMIN_V2.merge(headers)
    end

    def json_admin_response
      response.body.present? && JSON.parse(response.body)
    end
  end
end

# frozen_string_literal: true

module ApiSpecHelper
  module ApiAutomationHelper
    HEADERS = {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => ClarkAPI::AutomationHelpers::Root::API_VERSION_HEADER
    }.freeze

    def json_auto_helper_post(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash.to_json, headers: HEADERS.merge(headers)
    end

    def json_auto_helper_put(endpoint, payload_hash={}, headers={})
      put endpoint, params: payload_hash.to_json, headers: HEADERS.merge(headers)
    end

    def json_auto_helper_get(endpoint, query_params={}, headers={})
      get endpoint, params: query_params, headers: HEADERS.merge(headers)
    end

    def json_auto_helper_patch(endpoint, payload_hash={}, headers={})
      patch endpoint, params: payload_hash.to_json, headers: HEADERS.merge(headers)
    end

    def json_auto_helper_delete(endpoint, payload_hash={}, headers={})
      delete endpoint, params: payload_hash.to_json, headers: HEADERS.merge(headers)
    end

    def json_auto_helper_response
      response.body.present? && JSON.parse(response.body)
    end
  end
end

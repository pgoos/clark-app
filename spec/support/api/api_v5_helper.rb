# frozen_string_literal: true

module ApiSpecHelper
  module ApiV5Helper
    DEFAULT_API_HEADERS_V5 = {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => ClarkAPI::V5::Root::API_VERSION_HEADER
    }.freeze

    def json_post_v5(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def post_v5(endpoint, payload_hash={}, headers={})
      post endpoint, params: payload_hash, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def json_put_v5(endpoint, payload_hash={}, headers={})
      put endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def json_get_v5(endpoint, query_params={}, headers={})
      get endpoint, params: query_params, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def json_patch_v5(endpoint, payload_hash={}, headers={})
      patch endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def json_delete_v5(endpoint, payload_hash={}, headers={})
      delete endpoint, params: payload_hash.to_json, headers: DEFAULT_API_HEADERS_V5.merge(headers)
    end

    def json_response
      response.body.present? && JSON.parse(response.body)
    end

    def json_attributes
      json_response && json_response["data"]["attributes"]
    end

    def mock_login_as(customer)
      login_as(customer.id, scope: :customer)
      interactor_result = double(Utils::Interactor::Result.name, successful?: true, customer: customer)
      allow(::Customer).to receive(:find).with(customer.id).and_return(interactor_result)
    end

    def login_customer(customer, scope:)
      case scope
      when :user
        user = User.find_by(mandate_id: customer.id)
        login_as(user, scope: :user)
      when :lead
        lead = Lead.find_by(mandate_id: customer.id)
        login_as(lead, scope: :lead)
      end
    end
  end
end

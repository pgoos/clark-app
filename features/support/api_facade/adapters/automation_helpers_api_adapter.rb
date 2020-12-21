# frozen_string_literal: true

# Class provides interfaces for the interaction with Automation Helpers API resources
class AutomationHelpersAPIAdapter
  # @param client [Client]
  def initialize(client)
    @client = client
  end

  # ClarkAPI::AutomationHelpers::FeatureSwitchScripts ------------------------------------------------------------------

  # @param key [String] feature key
  # @param active [Boolean] feature target state
  def switch_feature(key, active)
    @client.execute_http_request("put",
                                 "/api/automation_helpers/feature_switch/switch_feature",
                                 200,
                                 body: { script_params: { key: key, active: active } })
  end

  # @param key [String] feature key
  # @param active [Boolean] feature target state
  def switch_setting_app_feature(key, active)
    @client.execute_http_request("put",
                                 "/api/automation_helpers/feature_switch/switch_setting_app_feature",
                                 200,
                                 body: { script_params: { key: key, active: active } })
  end

  # ClarkAPI::AutomationHelpers::SetupDataScripts ----------------------------------------------------------------------

  # TODO: refactor this this method, related API resource and add docs here [JCLARK-57846]
  def post_create_new_product(product_attributes)
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/setup_products",
                                 201,
                                 params: product_attributes)
  end

  # @param customer_state [String] should be in [self service, mandate]
  # @return [Hash] customer details
  def post_create_new_customer(customer_state)
    states = { "self service" => "self_service", "mandate" => "mandate_customer" }

    unless states.key?(customer_state)
      raise ArgumentError.new("customer_state expected to be in [self service, mandate], but was #{customer_state}")
    end

    script_params = { script_params: { attributes: { customer_state: states[customer_state] } } }
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/create_customer",
                                 201,
                                 params: script_params)
  end

  # @param mandate_fields [String] should be in [self service, mandate]
  # @return [Hash] customer details
  def post_update_owner_ident(owner_ident, customer)
    fields = { "owner_ident": owner_ident, "mandate_id": customer.mandate_id }
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/update_mandate_fields",
                                 201,
                                 params: { script_params: fields })
  end

  # @param customer_email [String]
  # @return [Hash] contract details
  def post_create_new_contract(customer_email)
    script_params = { script_params: { customer_email: customer_email } }
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/create_contract",
                                 201,
                                 params: script_params)
  end

  def post_create_signature_for_mandate
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/create_signature_for_mandate",
                                 201,
                                 params: { script_params: { mandate_id: @client.session.current_user_mandate_id } })
  end

  def post_create_new_offer(offer_attributes)
    @client.execute_http_request("post",
                                 "/api/automation_helpers/data_setup/execute/create_offer_setup",
                                 201,
                                 params: offer_attributes)
  end

  # ClarkAPI::AutomationHelpers::TaskExecutorScripts -------------------------------------------------------------------

  # task name should consists of task namespace and task name e.g "transactional_mails:mandate_reminder1"
  # otherwise exception will be thrown
  # param task_name [String]
  def execute_task(task_name)
    @client.execute_http_request("post",
                                 "/api/automation_helpers/task_executor",
                                 201,
                                 params: { script_params: { task: task_name } })
  end
end

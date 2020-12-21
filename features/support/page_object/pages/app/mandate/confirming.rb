# frozen_string_literal: true

require_relative "abstract_confirming.rb"

module AppPages
  # /de/app/mandate/confirming
  class Confirming < AbstractConfirming
    # Page specific methods ----------------------------------------------------------------
    private

    def insign_element
      find("#insign-iframe")
    end

    # extend Components::Checkbox --------------------------------------------------------------------------------------

    def select_incentive_funnel_condition_checkbox
      find(".cucumber-incentive-funnel-condition-checkbox").find("div.custom-checkbox").click
    end

    def select_incentive_funnel_consent_checkbox
      find(".cucumber-incentive-funnel-consent-checkbox").find("div.custom-checkbox").click
    end
  end
end

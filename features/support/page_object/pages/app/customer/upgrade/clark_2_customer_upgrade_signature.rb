# frozen_string_literal: true

require_relative "../../mandate/abstract_confirming.rb"
require_relative "../../../../components/input.rb"

module AppPages
  # /de/app/customer/upgrade/signature
  class Clark2CustomerUpgradeSignature < AbstractConfirming
    include Components::Input
    # Page specific methods ----------------------------------------------------------------

    private

    def insign_element
      find('iframe[title="insign-iframe"]')
    end
  end
end

# frozen_string_literal: true

require_relative "../confirming.rb"

module AppPages
  # /de/app/mandate/confirming
  class ConfirmingHomeTwentyFour < Confirming
    # Page specific methods ----------------------------------------------------------------
    def select_home24_terms_condition_checkbox
      find(".cucumber-home24-checkbox-contract").click
    end

    def select_home24_signature_rules_checkbox
      find(".cucumber-home24-checkbox-advice").click
    end
  end
end

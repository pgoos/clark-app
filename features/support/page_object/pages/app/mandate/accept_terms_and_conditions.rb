# frozen_string_literal: true

require_relative "../../../components/checkbox.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/accept-terms
  class AcceptTermsAndConditions
    include Page
    include Components::Checkbox

    private

    # extend Components::Checkbox --------------------------------------------------------------------------------------

    def select_accept_privacy_policy_checkbox
      page.find(".cucumber-accept-terms-checkbox", match: :first).click
    end

    def select_the_terms_of_use_checkbox
      page.all(".cucumber-accept-terms-checkbox")[1].click
    end
  end
end

# frozen_string_literal: true

require_relative "../page.rb"
require_relative "../../components/input.rb"

module AppPages
  # /de/app/mandate/invitations
  class InviteFriend
    include Page
    include Components::Input

  # Page specific methods --------------------------------------------------------------------------------------------

    def enter_customer_data_invitee_email(customer)
      find("#email").send_keys(customer.invitee_email)
      sleep 1
    end
  end
end

# frozen_string_literal: true

module AuditHelpers
  def disable_audit
    allow(BusinessEvent).to receive(:audit).and_return(true)
  end
end

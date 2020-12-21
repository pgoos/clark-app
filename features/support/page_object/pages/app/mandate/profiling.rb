# frozen_string_literal: true

require_relative "abstract_profiling.rb"

module AppPages
  # /de/app/mandate/profiling
  class Profiling < AbstractProfiling

    # Page specific methods --------------------------------------------------------------------------------------------
    # TODO: transform these methods to component' methods
    def fill_profiling_form(customer)
      super
      set_field_value("email", customer.email)
      sleep 0.25
    end

  end
end

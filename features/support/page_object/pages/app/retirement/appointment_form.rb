# frozen_string_literal: true

require_relative "../../../components/calendar.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/retirement/appointment
  class AppointmentForm
    include Page
    include Components::Calendar
  end
end

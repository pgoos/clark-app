# frozen_string_literal: true

require_relative "../questionnaire.rb"

module AppPages
  # /de/app/retirement-check/questionnaire
  class RentencheckQuestionnaire < Questionnaire
    # This method is being used via reflection as follows: send("click_#{marker.tr(' ', '_')}_icon", icon)
    def click_on_calendar_icon(_)
      find(".cucumber-datepicker").click
      find(".picked").click
    end
  end
end

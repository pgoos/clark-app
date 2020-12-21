# frozen_string_literal: true

require_relative "../../../components/radio_button.rb"
require_relative "../../../components/calendar.rb"
require_relative "../../../components/checkout_stepper.rb"

module AppPages
  # /de/app/offers/(:?\d+)/checkout/(:?\d+)/start-date
  class CheckoutStartDate
    include Page
    include Components::CheckoutStepper
    include Components::RadioButton
    include Components::Calendar

    private

    # extend Components::RadioButton -----------------------------------------------------------------------------------

    def select_insurance_start_date_radio_button(option)
      if option == "Nächster Werktag"
        page.find(".cucumber-next-working-day-choice").click
      elsif option == "Später"
        page.find(".cucumber-later-choice").click
      else
        raise ArgumentError, "No such radio button with the name #{option}"
      end
    end

    def select_previous_damage_radio_button(option)
      if option == "Nein"
        page.find(".cucumber-previous-damage-no-choice").click
      elsif option == "Ja, ich hatte Schäden"
        page.find(".cucumber-previous-damage-yes-choice").click
      else
        raise ArgumentError, "No such radio button with the name #{option}"
      end
    end

    # Components::Calendar ---------------------------------------------------------------------------------------------

    def open_calendar
      page.find("input.cucumber-insurance-start-date-picker").click
    end

    def select_date(target_date)
      page.find("input.cucumber-insurance-start-date-picker").send_keys(target_date.strftime("%d.%m.%Y"))
    end

    def select_date_in_start_date_calendar(date)
      return select_next_business_day if date == "next business"
      select_date(date)
    end

    # Components::Input ------------------------------------------------------------------------------------------------

    def enter_value_into_previous_damage_input_field(value)
      page.find(".cucumber-previous-damage-text-field").send_keys(value)
    end
  end
end

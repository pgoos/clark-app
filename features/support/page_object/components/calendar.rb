# frozen_string_literal: true

require "date"
require "time"
require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component is responsible for picking dates in date pickers and time pickers
  module Calendar
    extend Helpers::Wrappers

    sleep_after 0.25, :select_date_in_calendar, :select_time

    # Define private constants
    EMBER_CALENDAR_CSS = "div.ember-power-calendar"
    EMBER_CALENDAR_NAV_TITLE_CSS = "div.ember-power-calendar-nav-title"
    EMBER_CALENDAR_DAY_CSS = "button.ember-power-calendar-day--current-month"
    private_constant :EMBER_CALENDAR_CSS
    private_constant :EMBER_CALENDAR_NAV_TITLE_CSS
    private_constant :EMBER_CALENDAR_DAY_CSS

    # Method selects date in date pickers
    # Custom method can be implemented. Example: def select_date_in_appointment_calendar(date) { }
    # If there is no custom method, will try to search for the date picker by label
    # If date is 'next business' day, will try to pick next business day in default calendar
    # @param date [String|Date] string with date or 'next business' value
    # @param marker [String, nil] custom method marker
    def select_date_in_calendar(date, marker=nil)
      # dispatch
      unless marker.nil?
        custom_method = "select_date_in_#{marker.tr(' ', '_')}_calendar"
        return send(custom_method, date) if respond_to?(custom_method, true)
      end

      if date == "next business"
        # generic implementation for 'next business day' for pages with single calendar
        select_next_business_day
      elsif marker.nil?
        select_date(date)
      elsif page.has_css?("label", text: marker, wait: 1)
        # generic implementation for pages with calendars, that could be found by parent label object
        find("label", text: marker).find(:xpath, "..").find(".date-input").click # open ember datepicker
        select_date(date.to_date) # select date
      else
        raise ArgumentError.new
      end
    end

    # Method selects time in time picker
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def select_appointment_time(time) { }
    # @param time [String] target time
    # @param marker [String] custom method marker
    def select_time(time, marker)
      send("select_#{marker.tr(' ', '_')}_time", time)
    end

    private

    # Selects a provided date in Ember Power Calendar. A calendar should be opened before invoking this method
    # @param target_date [Date]
    def select_date(target_date)
      # get opened Ember Power Calendar and parse selected date
      ember_calendar = Capybara.current_session.find(EMBER_CALENDAR_CSS)
      selected_date = Date.strptime(ember_calendar.find(EMBER_CALENDAR_NAV_TITLE_CSS).text, "%d.%m.%Y")

      # select year
      year_nav_btn = target_date.year > selected_date.year ? "»" : "«"
      (target_date.year - selected_date.year).abs.times { ember_calendar.find_button(year_nav_btn).click }

      # select month
      month_nav_btn = target_date.month > selected_date.month ? "›" : "‹"
      (target_date.month - selected_date.month).abs.times { ember_calendar.find_button(month_nav_btn).click }

      # select day
      day_button = ember_calendar.find(EMBER_CALENDAR_DAY_CSS, text: target_date.day, match: :prefer_exact)
      return false if day_button.disabled? # the day us a public holiday
      day_button.click
      true
    end

    # Find next business day and select it in a calendar
    # Will throw exceptions if several calendars are present on a page
    def select_next_business_day
      puts "Current date and time is #{DateTime.now.strftime('%a %d %b %Y at %I:%M%p')}"
      next_business_day = lambda do |date|
        date += 1
        return date unless [0, 6].include?(date.wday) # the week starts from Sunday
        next_business_day.call(date)
      end
      open_calendar # override if needed
      # iterate over next 7 days to handle the situation when the next mon-fri day is a public day
      (0...6).each { |i| break if select_date(next_business_day.call(Date.today + i)) }
    end

    def open_calendar
      Capybara.current_session.find("span.cucumber-date-picker").click # open datepicker
    end

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # If test doesn't not validate appointment time - choose 'default' as a time
    # If test does validate appointment choose <b>20:00 ONLY</b> to reduce flakiness
    def select_appointment_time(time)
      options_name_box = "timeslot"
      if time == "default"
        within "##{options_name_box}" do
          find("option[id='select-default-option']").click
        end
      else
        page.select time, from: options_name_box
      end
    end
  end
end

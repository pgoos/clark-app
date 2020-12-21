require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'
require 'date'

class TodosPage < PageObject
  attr_reader :path, :appointment_path

  def initialize(locale = I18n.locale)
    @locale = locale
    @path = polymorphic_path([:manager, :todolist], locale: @locale)
    @appointment_path = polymorphic_path([:manager, :appointment], locale: @locale)
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  # Navigate to the todos view
  def navigate
    visit @path
  end

  # Navigate to the make appointment page
  def navigate_appointment
    visit @appointment_path
  end

  def check_continue_mandate_redirect(class_name)
    self.submit_online
    btn = find('.recommendations__continue-mandate__cta-list__item .btn-primary')
    @emberHelper.ember_transition_click btn
    page.assert_selector(".#{class_name}", visible: true)
  end

  def click_cta_continue_mandate
    find('.recommendations__continue-mandate__cta-list__item .btn-primary').click
  end

  def check_continue_mandate_modal_visible
    self.submit_online
    page.assert_selector('.recommendations__continue-mandate', visible: true)
  end

  def submit_phone
    click_button('Termin vereinbaren')
  end

  def submit_online
    find('.recommendations__item__cta').click
  end

  def fill_in_date
    find('.datepicker').click
    find('li[data-view=year]', match: :first).click
    find('li[data-view=month]', match: :first).click
    find('li[data-view=day]', match: :first).click
  end

  def today
    date = Date.today
    date.strftime("%d.%m.%Y")
  end

  def date_past
    date = Date.today
    date = self.skip_weekends(date, -1)
    date.strftime("%d.%m.%Y")
  end

  def date_weekend
    date = Date.today
    date = self.next_weekend_day(date)
    date.strftime("%d.%m.%Y")
  end

  def date_correct
    date = Date.today
    date = self.skip_weekends(date, +1)
    date.strftime("%d.%m.%Y")
  end

  def in_one_hour
    time = 1.hour.from_now
    time.strftime("%I:%M")
  end

  def correct_appointment_time
    appontment = Date.tomorrow.at_middle_of_day
    # Make sure its not on the weekend
    appontment = self.skip_weekends(appontment, +1)
    appontment
  end

  def next_weekend_day(date)
    while (date.wday != 0) and (date.wday != 6) do
      date += 1
    end
    date
  end

  def skip_weekends(date, inc)
    date += inc
    while (date.wday == 0) or (date.wday == 6) do
      date += inc
    end
    date
  end

end

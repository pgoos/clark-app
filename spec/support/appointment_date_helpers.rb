# frozen_string_literal: true

module AppointmentDateHelpers
  def holiday?(date)
    Settings.holidays[:DE].include?(date)
  end

  def next_saturday
    today = Time.zone.today
    offset = today.wday
    return today.advance(days: 7) if offset == 6
    today.advance(days: 6 - offset)
  end

  def next_sunday
    Time.zone.today.advance(days: 7 - Time.zone.now.wday)
  end

  def last_monday
    Time.zone.today.monday - 1.week
  end

  def next_monday
    Time.zone.today.monday + 1.week
  end

  def date_outside_weekend(date)
    return date_outside_weekend(date - 1.day) if holiday?(date)
    return date - 1.day if date.saturday?
    return date - 2.days if date.sunday?
    date
  end

  def next_monday_thats_not_holiday
    date = next_monday
    date += 1.week while holiday?(date)
    date
  end

  def next_non_hollyday_after_monday
    date = next_monday
    date += 1.day while holiday?(date)
    date
  end

  def last_monday_thats_not_holiday
    date = last_monday
    date -= 1.week while holiday?(date)
    date
  end

  def next_holiday_in_month
    holiday_date = nil
    (DateTime.current..1.month.from_now).each do |date|
      holiday_date = date if holiday?(date)
    end
    holiday_date
  end

  def not_holiday_date_next_month
    date = 5.weeks.from_now.to_date
    date += 1.week while holiday?(date)
    date += 1.day if date.sunday?
    date
  end
end

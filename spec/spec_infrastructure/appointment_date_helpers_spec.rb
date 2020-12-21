# frozen_string_literal: true

require "rails_helper"

class DummyClass
  include(AppointmentDateHelpers)
end

RSpec.describe AppointmentDateHelpers do
  subject { DummyClass.new }

  describe ".next_saturday" do
    it "should return a date with Saturday" do
      0.upto(6) do |n|
        Timecop.travel(Time.zone.today.advance(days: n))
        expect(subject.next_saturday).to be_saturday
      end
    end

    it "should return next week's Saturday if the day is already Saturday" do
      Timecop.travel(Time.zone.today.advance(days: 6 - Time.zone.today.wday)) do
        expect(subject.next_saturday).to eq(Time.zone.today + 7.days)
      end
    end
  end
end

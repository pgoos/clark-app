require 'rails_helper'

RSpec.describe UtcOffsetCalculator do
  Time.use_zone("Europe/Berlin") do

    it 'should calculate the utc offset for a winter date' do
      winter_date = Date.new(2016, 3, 26)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(winter_date)).to eq(1)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(winter_date)).to eq(1)
    end

    it 'should calculate the utc offset for a date switching to summer time' do
      switch_to_summer = Date.new(2016, 3, 27)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(switch_to_summer)).to eq(1)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(switch_to_summer)).to eq(2)
    end

    it 'should calculate the utc offset for the first complete day within summer time' do
      first_summer_date = Date.new(2016, 3, 28)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(first_summer_date)).to eq(2)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(first_summer_date)).to eq(2)
    end

    it 'should calculate the utc offset for the last complete day within summer time' do
      last_summer_date = Date.new(2016, 10, 29)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(last_summer_date)).to eq(2)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(last_summer_date)).to eq(2)
    end

    it 'should calculate the utc offset for a date switching to winter time' do
      switch_to_winter = Date.new(2016, 10, 30)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(switch_to_winter)).to eq(2)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(switch_to_winter)).to eq(1)
    end

    it 'should calculate the utc offset for a date properly respecting winter time' do
      winter_date = Date.new(2016, 10, 31)
      expect(UtcOffsetCalculator.utc_day_start_offset_for_date(winter_date)).to eq(1)
      expect(UtcOffsetCalculator.utc_day_end_offset_for_date(winter_date)).to eq(1)
    end
  end
end
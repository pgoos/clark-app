# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::Geo::GermanPlace do
  it "has 16 provinces" do
    expect(GERMAN_PLACES.provinces.count).to eq(16)
  end

  it "has all zipcodes on the 5 digit format" do
    expect(GERMAN_PLACES.zip_codes.map(&:size).uniq).to eq([5])
  end
end

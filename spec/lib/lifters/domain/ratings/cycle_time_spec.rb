# frozen_string_literal: true

require "spec_helper"
require "dry-struct"
require_relative "../../../../../config/initializers/dry_types"
require_relative "../../../../../lib/lifters/domain/ratings/cycle_time"

RSpec.describe Domain::Ratings::CycleTime do
  let(:positive1view) { 120 }
  let(:positive2view) { 180 }
  let(:no_rating)     { 180 }
  let(:bad_rating)    { 360 }
  let(:attributes) do
    {
      positive1view: positive1view,
      positive2view: positive2view,
      no_rating: no_rating,
      bad_rating: bad_rating
    }
  end

  describe ".new" do
    it "maps the correct attributes" do
      cycle_time = described_class.new(attributes)

      expect(cycle_time.positive1view).to eq positive1view
      expect(cycle_time.positive2view).to eq positive2view
      expect(cycle_time.no_rating).to eq no_rating
      expect(cycle_time.bad_rating).to eq bad_rating
    end

    it "ensure attribute types" do
      cycle_time = described_class.new(attributes)

      expect(cycle_time.positive1view).to be_an(Integer)
      expect(cycle_time.positive1view).not_to be_negative

      expect(cycle_time.positive2view).to be_an(Integer)
      expect(cycle_time.positive2view).not_to be_negative

      expect(cycle_time.no_rating).to be_an(Integer)
      expect(cycle_time.no_rating).not_to be_negative

      expect(cycle_time.bad_rating).to be_an(Integer)
      expect(cycle_time.bad_rating).not_to be_negative
    end
  end
end

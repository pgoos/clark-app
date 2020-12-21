# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::FuturePointValue, type: :model do
  describe ".all" do
    it "returns collection" do
      vals = described_class.all
      expect(vals).to be_kind_of Array
      expect(vals.count).to be_positive
    end
  end

  describe ".find_by_date" do
    it "returns object with specific birth year" do
      val = described_class.find_by_date(Date.parse("01-01-2050"))
      expect(val).to be_present
      expect(val).to be_kind_of Retirement::FuturePointValue
    end
  end
end

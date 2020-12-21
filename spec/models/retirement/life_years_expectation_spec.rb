# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::LifeYearsExpectation, type: :model do
  describe ".all" do
    it "returns collection" do
      expections = described_class.all
      expect(expections).to be_kind_of Array
      expect(expections.count).to be_positive
    end
  end

  describe ".find_by_birth_year" do
    it "returns object with specific birth year" do
      deathy = described_class.find_by_birth_year(1990)
      expect(deathy).to be_present
      expect(deathy).to be_kind_of Retirement::LifeYearsExpectation
    end
  end
end

# frozen_string_literal: true

module DateMatchers
  RSpec::Matchers.define :be_the_same_date do |expected|
    match do |actual|
      expect(expected.to_date).to eq(actual.to_date)
    end
  end
end

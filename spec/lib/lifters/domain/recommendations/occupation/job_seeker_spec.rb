# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::Occupation::JobSeeker do
  describe ".call" do
    it "returns placeholder categories' idents" do
      expect(described_class.call(nil)).to match_array(%w[2fc69451 03b12732])
    end
  end
end

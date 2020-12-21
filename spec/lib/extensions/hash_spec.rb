# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hash do
  describe ".trim_string_values!" do
    it "doesn't change hash values if they don't have spaces" do
      old_hash = {a: 1, foo: "bar"}
      new_hash = old_hash.dup.trim_string_values!
      expect(old_hash).to eq(new_hash)
    end

    it "removes spaces from hash values" do
      old_hash     = {a: "  first ", b: "second        ", c: "third"}
      correct_hash = {a: "first", b: "second", c: "third"}
      expect(old_hash.trim_string_values!).to eq(correct_hash)
    end
  end
end

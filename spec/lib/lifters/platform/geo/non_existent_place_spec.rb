# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::Geo::NonExistentPlace do
  subject { described_class.new("12345") }

  it "'is a' place" do
    expect(described_class.include?(Platform::Geo::Place)).to eq(true)
  end

  it "does not exists" do
    expect(subject.exists?).to eq(false)
  end

  it "exposes name" do
    expect(subject.name).to be_nil
  end

  it "expose zip" do
    expect(subject.zip).to eq("12345")
  end
end

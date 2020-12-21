# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::Geo::ExistingPlace do
  subject { described_class.new("Hessen", "60322") }

  it "'is a' place" do
    expect(described_class.include?(Platform::Geo::Place)).to eq(true)
  end

  it "exists" do
    expect(subject.exists?).to eq(true)
  end

  it "exposes name" do
    expect(subject.name).to eq("Hessen")
  end

  it "expose zip" do
    expect(subject.zip).to eq("60322")
  end
end

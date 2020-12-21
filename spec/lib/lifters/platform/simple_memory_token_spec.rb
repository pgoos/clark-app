# frozen_string_literal: true
require "rails_helper"

RSpec.describe Platform::SimpleMemoryToken do
  let(:time) { Time.zone.now }
  let(:user) { create(:user, created_at: time) }
  let(:mandate) { create(:mandate, user: user, created_at: time) }
  let(:token) { Digest::SHA1.hexdigest "#{time}%#{user.id}%#{time}%#{mandate.id}" }

  it "generates a token" do
    expect(described_class.new(mandate).token).to eq(token)
  end

  it "generates a randomized token if random is true" do
    first_token = described_class.new(mandate, true).token
    second_token = described_class.new(mandate, true).token
    expect(first_token).not_to eq(second_token)
  end

  it "generates a token if the mandate has a lead instead of a user" do
    lead = create(:lead)
    expect(described_class.new(lead.mandate).token).not_to be_nil
  end

  it "validates a token when true" do
    expect(described_class.new(mandate).valid?(token)).to eq(true)
  end

  it "validates a token when false" do
    expect(described_class.new(mandate).valid?("bananas")).to eq(false)
  end
end

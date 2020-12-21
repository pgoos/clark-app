# frozen_string_literal: true
# == Schema Information
#
# Table name: acquisition_partners
#
#  id              :integer          not null, primary key
#  username        :string
#  password_digest :string
#  enabled         :boolean          default(TRUE)
#  networks        :text             default([]), is an Array
#  meta            :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#


require "rails_helper"

RSpec.describe AcquisitionPartner, type: :model do
  # Setup
  # Settings
  # Constants
  VALID_USERNAME = "PartnerABC"
  INVALID_USERNAME = "Invalid User Name 123"
  VALID_PASSWORD = "nottooshort"
  INVALID_PASSWORD = "shrt"
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations
  # Callbacks
  # Instance Methods
  it "fails because of no password" do
    expect(described_class.new(username: VALID_USERNAME).save).to be false
  end

  it "fails because password is too short" do
    expect(described_class.new(username: VALID_USERNAME, password: INVALID_PASSWORD).save).to be false
  end

  it "refuses a shitty username" do
    expect(described_class.new(username: INVALID_USERNAME, password: VALID_PASSWORD).save).to be false
  end

  it "succeeds because password is long enough and username is okay" do
    expect(described_class.new(username: VALID_USERNAME, password: VALID_PASSWORD).save).to be true
  end

  it "refuses because username is not unique" do
    expect(described_class.new(username: VALID_USERNAME, password: VALID_PASSWORD).save).to be true
    expect(described_class.new(username: VALID_USERNAME, password: VALID_PASSWORD).save).to be false
  end

  it "authenticates" do
    expect(described_class.new(username: VALID_USERNAME, password: VALID_PASSWORD).save).to be true
    expect(described_class.find_by(username: VALID_USERNAME).try(:authenticate, VALID_PASSWORD)).to be_truthy
  end

  it "returns a proper networks query string" do
    subject.networks = %w[questler tmux]
    expect(subject.query_friendly_networks).to eql("'questler','tmux'")
  end

  it "returns a proper networks query string with SQL special characters quoted" do
    subject.networks = %w[ques'tler tmux]
    expect(subject.query_friendly_networks).to eql("'ques''tler','tmux'")
  end
  # Class Methods
end

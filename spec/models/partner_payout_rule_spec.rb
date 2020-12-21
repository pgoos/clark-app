# frozen_string_literal: true

# == Schema Information
#
# Table name: partner_payout_rules
#
#  id             :bigint(8)        not null, primary key
#  mandate_created_from           :date     not null
#  mandate_created_to             :date     not null
#  products_count                 :integer
#  payout_amount                  :integer  not null
#  partner_id                     :integer  not null
#
# Indexes
#
#  partner_payout_unique  (mandate_created_from, mandate_created_to, partner_id) UNIQUE
#
require "rails_helper"

RSpec.describe PartnerPayoutRule, type: :model do
  subject { build(:partner_payout_rule) }
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:mandate_created_from) }
  it { is_expected.to validate_presence_of(:mandate_created_to) }
  it { is_expected.to validate_presence_of(:payout_amount) }
  it { is_expected.to validate_presence_of(:partner_id) }
  it { is_expected.to validate_uniqueness_of(:partner_id).scoped_to([:mandate_created_from, :mandate_created_to]) }

  context "end_date_after_start_date" do
    it "validates when created to is less than created from" do
      subject.mandate_created_to = subject.mandate_created_from - 1.day
      expect(subject).not_to be_valid
    end
  end
  # Callbacks
  # Instance Methods
  # Class Methods
end

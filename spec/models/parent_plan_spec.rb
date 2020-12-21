# frozen_string_literal: true

# == Schema Information
#
# Table name: plans
#
#  id                     :integer          not null, primary key
#  name                   :string
#  state                  :string
#  plan_state_begin       :date
#  out_of_market_at       :date
#  created_at             :datetime
#  updated_at             :datetime
#  coverages              :jsonb
#  category_id            :integer
#  company_id             :integer
#  subcompany_id          :integer
#  metadata               :jsonb
#  insurance_tax          :float
#  ident                  :string
#  premium_price_cents    :integer          default(0)
#  premium_price_currency :string           default("EUR")
#  premium_period         :string
#

require "rails_helper"

RSpec.describe ParentPlan, :slow, type: :model do
  # Setup

  subject { build(:plan, name: "Plan #1") }

  it { is_expected.to be_valid }

  # Settings

  it { is_expected.to monetize(:premium_price_cents) }

  # Constants
  # Attribute Settings

  %i[name state].each do |attr|
    it { is_expected.to be_respond_to(attr) }
  end

  # Plugins
  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "an activatable model"
  it_behaves_like "an auditable model"
  it_behaves_like "a model with coverages"

  # Index
  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:category) }
  it { expect(subject).to belong_to(:company) }
  it { expect(subject).to belong_to(:subcompany) }

  # Nested Attributes
  # Validations

  [:name].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  # Callbacks
  # Delegates
  # Instance Methods
  # Class Methods
  # Protected
  # Private
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id             :bigint(8)        not null, primary key
#  name           :string
#  ident          :string           not null
#  active         :boolean          default(TRUE)
#  owned_by_clark :boolean          default(FALSE)
#  metadata       :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_partners_on_ident  (ident) UNIQUE
#

require "rails_helper"

RSpec.describe Partner, type: :model do
  # Setup
  subject { FactoryBot.build(:partner) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  describe ".active" do
    let!(:active_partner) { create(:partner, :active) }
    let!(:inactive_partner) { create(:partner, :inactive) }

    it "should only return active partners" do
      expect(Partner.active.map(&:id)).to eq([active_partner.id])
    end
  end

  # Associations
  # Nested Attributes
  # Validations
  it { is_expected.to validate_presence_of(:ident) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:ident).ignoring_case_sensitivity }

  # Callbacks
  # Instance Methods
  # Class Methods
end

# frozen_string_literal: true
# == Schema Information
#
# Table name: follow_ups
#
#  id           :integer          not null, primary key
#  item_id      :integer
#  item_type    :string
#  admin_id     :integer
#  due_date     :datetime
#  comment      :string
#  acknowledged :boolean          default(FALSE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "rails_helper"

RSpec.describe FollowUp, type: :model do
  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  subject { FactoryBot.build(:follow_up) }

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it_behaves_like "an auditable model"

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Scopes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  # DB
  it { is_expected.to have_db_index(:created_at) }

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it "validates that due_date is in the future" do
    subject.update_attributes(due_date: 2.days.ago)
    expect(subject).not_to be_valid
  end

  it "validates that due_date is not nil" do
    subject.update_attributes(due_date: nil)
    expect(subject).not_to be_valid
  end

  it "does not validate due date when it is not changed" do
    # change the date to a past date
    subject.due_date = 4.days.ago
    subject.save(validate: false)

    # Now change something else and this should go through
    subject.update_attributes(acknowledged: true)
    expect(subject).to be_valid
  end

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it "sets the acknowledged attribute" do
    subject.acknowledge!
    expect(subject.acknowledged).to be_truthy
  end

  describe "#mandate" do
    subject(:follow_up) { described_class.new item: item }

    context "with Mandate follow up item" do
      let(:item) { Mandate.new }

      it { expect(follow_up.mandate).to eq item }
    end

    context "with Opportunity follow up item" do
      let(:item) { Opportunity.new mandate: mandate }
      let(:mandate) { Mandate.new }

      it { expect(follow_up.mandate).to eq mandate }
    end
  end

  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
end

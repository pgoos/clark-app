# frozen_string_literal: true

# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "rails_helper"

RSpec.describe Interaction::PhoneCall, type: :model do
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:admin) }
  it { is_expected.to validate_presence_of(:direction) }

  let(:admin) { create(:admin) }
  let(:mandate) { create(:mandate) }
  let(:content) { Faker::Lorem.characters(number: 100) }
  let(:opportunity) { create(:opportunity) }

  describe ".create" do
    it "creates an automated reminder for a missed outgoing call on an opportunity in contact phase" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                                           mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
    end

    it "creates an automated reminder for a missed outgoing call on an opportunity in offer phase" do
      opportunity.state = :offer_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                                           mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
    end

    it "creates an automated reminder for a need follow up outgoing call on an opportunity in contact phase" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                                           mandate: mandate, status: described_class::STATUS_NEED_FOLLOW_UP,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
    end

    it "creates an automated reminder for a need follow up outgoing call on an opportunity in offer phase" do
      opportunity.state = :offer_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                                           mandate: mandate, status: described_class::STATUS_NEED_FOLLOW_UP,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
    end

    it "does not create an automated reminder for a missed outgoing call on an opportunity not in offer or contact phase" do
      opportunity.state = :created
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                                           mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(0)
    end

    it "does not create an automated reminder for incoming calls on an opportunity in contact phase" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:in],
                                           mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                                           topic: opportunity)
      expect(FollowUp.all.count).to eq(0)
    end

    it "does not create an automated reminder for outgoing calls on a mandate" do
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                             mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                             topic: mandate)
      expect(FollowUp.all.count).to eq(0)
    end

    it "creates an automated reminder for a missed outgoing call on an opportunity in contact phase after 2 days from now" do
      opportunity.state = :initiation_phase
      missed_call = described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                             mandate: mandate, status: described_class::STATUS_NOT_REACHED,
                             topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
      expect(FollowUp.first.item).to eq(missed_call.topic)
      expect(FollowUp.first.comment).not_to be_nil
    end

    it "creates an automated reminder with the specified interval if provided" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                             mandate: mandate, status: described_class::STATUS_NEED_FOLLOW_UP,
                             topic: opportunity, remind_after: 7)
      expect(FollowUp.all.count).to eq(1)
      expect(FollowUp.first.due_date).to be_the_same_date(Time.zone.today + 7.days)
    end

    it "defaults the automated reminder for two days if no interval is provided" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                             mandate: mandate, status: described_class::STATUS_NEED_FOLLOW_UP,
                             topic: opportunity)
      expect(FollowUp.all.count).to eq(1)
      expect(FollowUp.first.due_date).to be_the_same_date(Time.zone.today + 2.days)
    end

    it "does not create an automated reminder if remind after was -1" do
      opportunity.state = :initiation_phase
      described_class.create(content: content, admin: admin, direction: Interaction.directions[:out],
                             mandate: mandate, status: described_class::STATUS_NEED_FOLLOW_UP,
                             topic: opportunity, remind_after: -1)
      expect(FollowUp.all.count).to eq(0)
    end
  end

  describe "#is_successful?" do
    let(:phone_call) { FactoryBot.build(:interaction_phone_call) }

    it "marks the call only successful if it only is marked as reached" do
      phone_call.status = described_class::STATUS_REACHED
      expect(phone_call).to be_is_successful
    end

    it "marks the call as unsuccessful if it is marked as not reached" do
      phone_call.status = described_class::STATUS_NOT_REACHED
      expect(phone_call).not_to be_is_successful
    end

    it "marks the call as unsuccessful if it is marked as as needs follow up" do
      phone_call.status = described_class::STATUS_NEED_FOLLOW_UP
      expect(phone_call).not_to be_is_successful
    end
  end
end

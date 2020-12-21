# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::UnreadImportantMessages do
  let(:mandate) { create(:mandate) }

  context "with user" do
    let(:user) { create(:user, mandate: mandate) }
    let!(:interaction) {
      create(:interaction_unread_automated_message,
                         mandate: user.mandate)
    }

    it "has a count of 1 if important message" do
      expect(described_class.new(user).count).to eq(1)
    end

    it "has a count of 0 if user has no interactions" do
      interaction.destroy
      expect(described_class.new(user).count).to eq(0)
    end

    it "has a count of 0 if the interaction is acknowledged" do
      interaction.update(acknowledged: true)
      expect(described_class.new(user).count).to eq(0)
    end

    it "has a count of 0 if the interaction is not automated" do
      interaction.update(created_by_robo: false)
      expect(described_class.new(user).count).to eq(0)
    end

    it "has a count of 0 if the interaction is not message" do
      interaction.update(type: Interaction::Sms)
      expect(described_class.new(user).count).to eq(0)
    end
  end

  context "with lead" do
    let(:lead) { create(:lead, mandate: mandate) }
    let!(:interaction) {
      create(:interaction_unread_automated_message,
                         mandate: lead.mandate)
    }

    it "has a count of 1 if important message" do
      expect(described_class.new(lead).count).to eq(1)
    end

    it "has a count of 0 if user has no interactions" do
      interaction.destroy
      expect(described_class.new(lead).count).to eq(0)
    end

    it "has a count of 0 if the interaction is acknowledged" do
      interaction.update(acknowledged: true)
      expect(described_class.new(lead).count).to eq(0)
    end

    it "has a count of 0 if the interaction is not automated" do
      interaction.update(created_by_robo: false)
      expect(described_class.new(lead).count).to eq(0)
    end

    it "has a count of 0 if the interaction is not message" do
      interaction.update(type: Interaction::Sms)
      expect(described_class.new(lead).count).to eq(0)
    end
  end
end

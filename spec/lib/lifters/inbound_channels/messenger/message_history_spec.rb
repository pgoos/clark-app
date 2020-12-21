require 'rails_helper'

describe InboundChannels::Messenger::MessageHistory do
  describe ".get" do
    subject { InboundChannels::Messenger::MessageHistory.get(mandate,
                                                             limit: limit,
                                                             younger_than: younger_than,
                                                             older_than: older_than) }
    let(:limit) { 2 }
    let(:younger_than) { 30.minutes.ago }
    let(:older_than) { 5.minutes.ago }

    let!(:mandate) { create :mandate }
    let!(:message1) { create :interaction_message, mandate: mandate, created_at: 35.minutes.ago }
    let!(:message2) { create :interaction_message, mandate: mandate, created_at: 25.minutes.ago }
    let!(:message3) { create :interaction_message, mandate: mandate, created_at: 15.minutes.ago }
    let!(:message4) { create :interaction_message, mandate: mandate, created_at: 10.minutes.ago }
    let!(:message5) { create :interaction_message, mandate: mandate, created_at: 1.minutes.ago }

    context "when mandate has messages" do
      it "returns 'limit' most recent messages within time window" do
        expect(subject).to eq([message4, message3])
      end
    end

    context "when older_than is not given" do
      let(:older_than) { nil }

      it "returns 'limit' most recent messages" do
        expect(subject).to eq([message5, message4])
      end
    end

    context "when younger_than is not given" do
      let(:younger_than) { nil }

      it "returns 'limit' messages older than 'older_than'" do
        expect(subject).to eq([message4, message3])
      end
    end
  end
end

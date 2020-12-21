# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Messenger::Messages::UnreadOutgoingRepository do
  let(:subject) { described_class }
  let(:mandate) { create(:mandate) }

  let(:time) { Time.zone.now.middle_of_day }
  let(:three_days_ago) { (time - 3.days) }
  let(:three_days_ago_beginning) { three_days_ago.beginning_of_day }
  let(:three_days_ago_end) { three_days_ago.end_of_day }
  let(:four_days_ago) { three_days_ago_beginning - 1.second }
  let(:two_days_ago) { three_days_ago_end + 1.second }

  describe ".mandate_ids_with_non_reminded_message_count" do
    context "all messages are 3 days old" do
      before do
        [three_days_ago_beginning, three_days_ago, three_days_ago_end].each do |creation_time|
          create(:unread_outgoing_message, mandate: mandate, created_at: creation_time)
        end
      end

      it "should get the mandate_id with correct count" do
        expect(subject.mandate_ids_with_non_reminded_message_count[mandate.id]).to eq(3)
      end
    end

    context "all messages are more than 3 days old" do
      before { create(:unread_outgoing_message, mandate: mandate, created_at: four_days_ago) }

      it "should not have mandate_id in the hash" do
        expect(subject.mandate_ids_with_non_reminded_message_count).to eq({})
      end
    end

    context "all messages are less than 3 days old" do
      before { create(:unread_outgoing_message, mandate: mandate, created_at: two_days_ago) }

      it "should not have mandate_id in the hash" do
        expect(subject.mandate_ids_with_non_reminded_message_count).to eq({})
      end
    end

    context "4 days old message with 3 days old message" do
      before do
        create(:unread_outgoing_message, mandate: mandate, created_at: four_days_ago)
        create(:unread_outgoing_message, mandate: mandate, created_at: three_days_ago)
      end

      it "should get the mandate_id with correct count" do
        expect(subject.mandate_ids_with_non_reminded_message_count[mandate.id]).to eq(1)
      end
    end

    context "2 days old message with 3 days old message" do
      before do
        create(:unread_outgoing_message, mandate: mandate, created_at: two_days_ago)
        create(:unread_outgoing_message, mandate: mandate, created_at: three_days_ago)
      end

      it "should get the mandate_id with correct count" do
        expect(subject.mandate_ids_with_non_reminded_message_count[mandate.id]).to eq(2)
      end
    end

    context "some messages are reminded before" do
      before do
        create(:unread_outgoing_message, :reminded, mandate: mandate, created_at: three_days_ago)
        create(:unread_outgoing_message, mandate: mandate, created_at: three_days_ago_end)
      end

      it "should not include messages in the count that are reminded before" do
        expect(subject.mandate_ids_with_non_reminded_message_count[mandate.id]).to eq(1)
      end
    end
  end

  describe ".non_reminded_messages_from_last_3_days" do
    let!(:message1) { create(:unread_outgoing_message, mandate: mandate, created_at: three_days_ago) }
    let!(:message2) { create(:unread_outgoing_message, mandate: mandate, created_at: two_days_ago) }
    let!(:message3) { create(:unread_outgoing_message, mandate: mandate, created_at: time) }

    context "all messages are non reminded" do
      it "should fetch all unread non reminded messages from past 3 days" do
        expect(subject.non_reminded_messages_from_last_3_days.count).to eq(3)
        expect(subject.non_reminded_messages_from_last_3_days.pluck(:id)).to \
          match_array([message1.id, message2.id, message3.id])
      end
    end

    context "some messages are reminded" do
      let!(:message4) { create(:unread_outgoing_message, :reminded, mandate: mandate, created_at: time) }

      it "should fetch only unread non reminded messages from past 3 days" do
        expect(subject.non_reminded_messages_from_last_3_days.count).to eq(3)
        expect(subject.non_reminded_messages_from_last_3_days.pluck(:id)).not_to include(message4.id)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Messenger::Messages::IncomingRepository do
  let(:subject) { described_class }

  let(:time) { Time.zone.now.middle_of_day }
  let(:thirty_days_old) { time - 30.days }
  let(:thirty_one_days_old) { time - 31.days }
  let(:admin) { create(:admin) }

  let(:mandate1) { create(:mandate) }
  let(:mandate2) { create(:mandate) }

  describe "#paginated_mandate_ids" do
    context "messages are not more than 30 days old" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, created_at: time) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, created_at: thirty_days_old) }

      it "return uniq sorted mandate_ids that has incoming messages in last 30 days" do
        expect(subject.new.paginated_mandate_ids).to eq([mandate1.id, mandate2.id])
      end
    end

    context "messages are more than 30 days old" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, created_at: thirty_one_days_old) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, created_at: thirty_one_days_old) }

      it "should not return mandate_id for messages more than 30 days old" do
        expect(subject.new.paginated_mandate_ids).to eq([])
      end
    end

    context "with by_acknowledged filter" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2) }

      it "should only returns the mandate_id that has acknowledged messages" do
        expect(subject.new(by_acknowledged: "true").paginated_mandate_ids).to eq([mandate2.id])
      end

      it "should only returns the mandate_id that has unacknowledged messages" do
        expect(subject.new(by_acknowledged: "false").paginated_mandate_ids).to eq([mandate1.id])
      end
    end

    context "with by_admin_id filter" do
      let(:admin1) { create(:admin) }
      let(:admin2) { create(:admin) }

      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, admin_id: admin1.id) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, admin_id: nil) }

      it "should only returns the mandate_id that has messages with specific assignee" do
        expect(subject.new(by_admin_id: admin1.id).paginated_mandate_ids).to eq([mandate1.id])
      end

      it "should only returns the mandate_id that has messages with no assignee" do
        expect(subject.new(by_admin_id: "nil").paginated_mandate_ids).to eq([mandate2.id])
      end
    end

    context "when messages from revoked mandate exists" do
      let(:active_mandate) { create(:mandate) }
      let(:revoked_mandate) { create(:mandate, :revoked) }
      let(:permission_for_revoked_mandates) { create(:permission, :view_revoked_mandates) }
      let!(:message_from_active_mandate) do
        create(:incoming_message, :unread, mandate: active_mandate, created_at: Time.current)
      end
      let!(:message_from_revoked_mandate) do
        create(:incoming_message, :read, mandate: revoked_mandate, created_at: Time.current)
      end

      context "when current_admin_id is not passed in" do
        it "returns both active and revoked mandates" do
          expect(
            subject.new.paginated_mandate_ids
          ).to eq([revoked_mandate.id, active_mandate.id])
        end
      end

      context "when current_admin_is is passed in" do
        context "when current_admin is not permitted to view revoked mandates" do
          it "revoked_mandate is not returned" do
            expect(
              subject.new(current_admin_id: admin.id).paginated_mandate_ids
            ).to eq([active_mandate.id])
          end
        end

        context "when current_admin is permitted to view revoked mandates" do
          before do
            admin.permissions << permission_for_revoked_mandates
          end

          it "revoked_mandate is returned" do
            expect(
              subject.new(current_admin_id: admin.id).paginated_mandate_ids
            ).to eq([revoked_mandate.id, active_mandate.id])
          end
        end
      end
    end
  end

  describe "#get_mandates_with_messages" do
    let(:mandate_ids) { [mandate1.id, mandate2.id] }

    context "messages are not more than 30 days old" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, created_at: time) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, created_at: thirty_days_old) }

      it "return sorted mandates that has incoming messages in last 30 days" do
        mandates = subject.new.get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([mandate1.id, mandate2.id])
      end
    end

    context "messages are more than 30 days old" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, created_at: thirty_one_days_old) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, created_at: thirty_one_days_old) }

      it "should not return mandates for incoming messages more than 30 days old" do
        mandates = subject.new.get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([])
      end
    end

    context "with by_acknowledged filter" do
      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2) }

      it "should only returns the mandates that has acknowledged messages" do
        mandates = subject.new(by_acknowledged: "true").get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([mandate2.id])
      end

      it "should only returns the mandates that has unacknowledged messages" do
        mandates = subject.new(by_acknowledged: "false").get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([mandate1.id])
      end
    end

    context "with by_admin_id filter" do
      let(:admin1) { create(:admin) }
      let(:admin2) { create(:admin) }

      let!(:message1) { create(:incoming_message, :unread, mandate: mandate1, admin_id: admin1.id) }
      let!(:message2) { create(:incoming_message, :read, mandate: mandate2, admin_id: nil) }

      it "should only returns the mandates that has messages with specific assignee" do
        mandates = subject.new(by_admin_id: admin1.id).get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([mandate1.id])
      end

      it "should only returns the mandates that has messages with no assignee" do
        mandates = subject.new(by_admin_id: "nil").get_mandates_with_messages(mandate_ids)
        expect(mandates.map(&:id)).to eq([mandate2.id])
      end
    end
  end

  describe "#unacknowledged" do
    let!(:message1) { create(:interaction_unread_received_message, mandate: mandate1, created_at: time) }
    let!(:message2) { create(:interaction_unread_received_message, mandate: mandate1, created_at: thirty_days_old) }
    let!(:message3) { create(:interaction_unread_received_message, mandate: mandate2, created_at: thirty_one_days_old) }

    context "messages are not more than 30 days old" do
      it "should fetch all unacknowledged messages" do
        expect(subject.new.unacknowledged(mandate1.id).count).to eq(2)
        expect(subject.new.unacknowledged(mandate1.id).map(&:id)).to match_array([message1.id, message2.id])
      end
    end

    context "messages are more than 30 days old" do
      it "should not fetch old unacknowledged messages" do
        expect(subject.new.unacknowledged(mandate2.id).count).to eq(0)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe TransactionalMailer::SendUnreadMessageReminderJob, type: :job do
  describe ".perform" do
    let(:mandate) { create(:mandate) }
    let!(:user) { create(:user, mandate: mandate, subscriber: true) }
    let!(:document_type) { create(:document_type, template: "messenger_mailer/unread_messages_3days_reminder") }
    let(:time) { Time.zone.now.middle_of_day }
    let!(:message1) { create(:unread_outgoing_message, mandate: mandate, created_at: (time - 3.days)) }
    let!(:message2) { create(:unread_outgoing_message, mandate: mandate, created_at: (time - 2.days)) }

    before { Timecop.freeze(time) }

    after { Timecop.return }

    it "should send reminder to mandate" do
      expect(MessengerMailer).to \
        receive(:unread_messages_3days_reminder).with(mandate, 2).and_call_original
      subject.perform(mandate.id, 2)
    end

    it "should update reminded_at of selected messages" do
      subject.perform(mandate.id, 2)
      expect(Time.zone.parse(message1.reload.reminded_at)).to eq(time)
      expect(Time.zone.parse(message2.reload.reminded_at)).to eq(time)
    end

    it "creates an email interaction for the mandate" do
      expect { subject.perform(mandate.id, 2) }.to change(Interaction::Email, :count).by(1)
      expect(Interaction::Email.last.topic).to eq(mandate)
    end

    context "non-subscriber user" do
      let!(:user) { create(:user, mandate: mandate, subscriber: false) }

      it "does not create an email interaction for the mandate" do
        expect { subject.perform(mandate.id, 2) }.to change(Interaction::Email, :count).by(0)
      end
    end

    context "lead without email" do
      let!(:user) { create(:device_lead, mandate: mandate) }

      it "does not create an email interaction for the mandate" do
        expect { subject.perform(mandate.id, 2) }.to change(Interaction::Email, :count).by(0)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe OutboundChannels::PushWithSmsFallback do
  let!(:subject) { described_class.new }
  let(:mandate) { build(:mandate) }
  let(:admin) { build(:admin) }
  let(:device) { double(Device, human_name: "some iPhone") }

  let(:sms_content) { Faker::Lorem.characters(number: 640) }
  let(:sms_payload) do
    {
      mandate: mandate,
      content: sms_content,
      phone_number: "123123123"
    }
  end

  let(:push_payload) do
    {
      mandate: mandate,
      admin: admin,
      title: "Message to Self",
      content: "Premature Optimization, is the root...",
      clark_url: "de/truth",
      section: "manager"
    }
  end

  let(:new_push) { Interaction::PushNotification.new }
  let(:new_sms) { Interaction::Sms.new }

  before do
    Settings.sns.sandbox_disabled = false
    allow_any_instance_of(OutboundChannels::Sms).to receive(:send_sms)

    allow(mandate).to receive(:phone).and_return("123123123")
  end

  after do
    Settings.reload!
  end

  describe "#send" do
    context "push" do
      before do
        allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([device])
        allow(PushService).to receive(:send_and_save_interaction).and_return(new_push)
        allow(Mandate).to receive(:publish_event)
        allow(Rails).to receive_message_chain("logger.info")
      end

      it "sends a push" do
        expect(PushService).to receive(:send_and_save_interaction).and_return(new_push)
        subject.send_message(push_payload, {})
      end

      it "does not send an sms" do
        expect(Interaction::Sms).not_to receive(:create!)
        expect_any_instance_of(OutboundChannels::Sms).not_to receive(:send_sms)

        subject.send_message(push_payload, {})
      end

      it "communicates result was push" do
        expect(subject.send_message(push_payload, {}))
          .to be_a(Interaction::PushNotification)
      end

      it "logs errors with Raven" do
        expect(PushService).to receive(:send_and_save_interaction).and_raise
        expect(Raven).to receive(:capture_exception)
        expect(Rails).to receive_message_chain("logger.error")
        allow(Interaction::Sms).to receive(:create!).and_return(new_sms)
        allow_any_instance_of(OutboundChannels::Sms).to receive(:send_sms)

        subject.send_message(push_payload, {})
      end

      it "communicates result was nothing" do
        expect(PushService).to receive(:send_and_save_interaction).and_raise
        expect(Raven).to receive(:capture_exception)
        expect(Rails).to receive_message_chain("logger.error")
        allow(Interaction::Sms).to receive(:create!).and_return(new_sms)
        allow_any_instance_of(OutboundChannels::Sms).to receive(:send_sms)

        expect(subject.send_message(push_payload, {})).to be_nil
      end

      it "doesn't send a push when device has an empty :token and :arn" do
        mandate = create(:mandate, user: create(:user, devices: [create(:device, token: nil, arn: "")]))

        expect(Raven).not_to receive(:capture_exception)
        expect(OutboundChannels::Mocks::FakeRemotePushClient).not_to receive(:publish)

        subject.send_message(push_payload.merge(mandate: mandate), {})
      end
    end

    context "sms" do
      let(:user) { User.new devices: [] }

      context "when MESSAGE_ONLY feature switch is on" do
        before { allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(true) }

        it "does not send a sms" do
          expect(subject.send_message(push_payload, sms_payload)).to be(nil)
        end

        it "logs errors with Raven" do
          expect(Raven).to receive(:capture_exception)
          expect(Rails).to receive_message_chain("logger.error")

          subject.send_message(push_payload, sms_payload)
        end

        it "communicates result was nothing" do
          expect(Raven).to receive(:capture_exception)
          expect(Rails).to receive_message_chain("logger.error")

          expect(subject.send_message(push_payload, sms_payload)).to be_nil
        end
      end

      context "when MESSAGE_ONLY feature switch is off" do
        before { allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false) }

        it "sends a sms" do
          allow_any_instance_of(Domain::Interactions::SmsDispatcher).to receive(:dispatch).and_return(new_sms)

          expect(subject.send_message(push_payload, sms_payload))
            .to be_a(Interaction::Sms)
        end

        it "does not send an sms when the phone is an empty string" do
          expect_any_instance_of(Domain::Interactions::SmsDispatcher).not_to receive(:dispatch)

          sms_payload[:phone_number] = ""
          expect(subject.send_message(push_payload, sms_payload)).to be(nil)
        end
      end
    end
  end

  describe "integration" do
    let(:sms_content) { Faker::Lorem.characters(number: 640) }
    let(:mandate) { create(:mandate, phone: ClarkFaker::PhoneNumber.phone_number) }
    let(:real_sms) do
      {
        mandate: mandate,
        content: sms_content,
        admin: create(:admin),
        phone_number: mandate.phone
      }
    end

    let(:real_push) do
      {
        mandate: mandate,
        admin: create(:admin),
        title: "Message to Self",
        content: "Premature Optimization, is the root...",
        clark_url: "de/truth",
        section: "manager"
      }
    end

    it "sends push" do
      allow(mandate).to receive_message_chain("user_or_lead.devices.with_push_enabled").and_return([device])
      allow(PushService).to receive(:send_push_notification).with(mandate, any_args)
                                                            .and_return([device])
      expect {
        sent = subject.send_message(real_push, real_sms)
        expect(sent).to be_a(Interaction::PushNotification)
      }.to change { Interaction::PushNotification.count }.by(1)
    end
  end
end

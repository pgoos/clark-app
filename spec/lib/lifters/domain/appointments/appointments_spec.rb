# frozen_string_literal: true

require "rails_helper"

describe Domain::Appointments::Appointment do
  subject { described_class.new(appointment) }

  let(:appointment) { create(:appointment, state: :requested, appointable: appointable) }
  let(:body) { double(:body, decoded: "content") }
  let(:html_part) { double(:html_part, body: body) }
  let(:mailer) { double(:mailer, deliver_now: true, subject: "some subject", html_part: html_part) }

  before do
    allow(Features).to receive(:active?).and_call_original
  end

  context "with Feature APPOINTMENT_CONFIRMATION_NEW_BRANDING ON" do
    before do
      allow(Features).to receive(:active?).with(Features::API_NOTIFY_PARTNERS).and_return(true)
      allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(true)
      allow(Features).to receive(:active?).with(Features::APPOINTMENT_CONFIRMATION_NEW_BRANDING).and_return(true)
      allow(mailer).to receive_message_chain(:body, :encoded).and_return("content")
    end

    context "has the second confirmed appointment" do
      let(:appointable) { create :opportunity }
      let!(:accepted_appointment) { create(:appointment, state: :accepted, appointable: appointable) }

      before do
        appointment.update!(state: :accepted)
      end

      it "sends out the appointment confirmation email for partner offers" do
        allow(appointable).to receive(:via_product_partner?).and_return(true)

        expect(AppointmentMailer).to receive(:appointment_confirmation_for_partner_offer)
          .with(appointment)
          .and_return(mailer)

        subject.send_appointment_confirmation
      end

      it "send out the appointment confirmation email for phone calls" do
        expect(OfferMailer).to receive(:offer_appointment_confirmation_phone_call)
          .with(appointment)
          .and_return(mailer)

        subject.send_appointment_confirmation
      end
    end

    context "has one confirmed appointment" do
      let(:appointable) { create :opportunity }

      before do
        appointment.update!(state: :accepted)
      end

      it "sends out the appointment confirmation email for partner offers" do
        allow(appointable).to receive(:via_product_partner?).and_return(true)

        expect(AppointmentMailer).to receive(:appointment_confirmation_for_partner_offer)
          .with(appointment)
          .and_return(mailer)

        subject.send_appointment_confirmation
      end

      it "send out the appointment confirmation email" do
        expect(AppointmentMailer).to receive(:appointment_confirmation)
          .with(appointment)
          .and_return(mailer)

        subject.send_appointment_confirmation
      end
    end

    context "when topic is retirement" do
      let(:appointable) { create :retirement_cockpit }

      it "does not send any emails out" do
        expect(AppointmentMailer).not_to receive(:appointment_confirmation)
        subject.send_appointment_confirmation
      end
    end
  end

  context "with Feature APPOINTMENT_CONFIRMATION_NEW_BRANDING OFF" do
    before do
      allow(Features).to receive(:active?).with(Features::API_NOTIFY_PARTNERS).and_return(true)
      allow(Features).to receive(:active?).with(Features::APPOINTMENT_CONFIRMATION_NEW_BRANDING).and_return(false)
    end

    context "has an opportunity with offer" do
      let(:appointable) { create :opportunity_with_offer }

      it "DOES NOT send out the appointment confirmation email for partner offers" do
        allow(appointable).to receive(:via_product_partner?).and_return(true)

        expect(AppointmentMailer).to receive(:appointment_confirmation_for_partner_offer)
          .with(appointment)
          .and_return(mailer)

        subject.send_appointment_confirmation
      end

      it "DOES NOT send out the appointment confirmation email for phone calls" do
        expect(OfferMailer).not_to receive(:offer_appointment_confirmation_phone_call)

        subject.send_appointment_confirmation
      end
    end
  end
end

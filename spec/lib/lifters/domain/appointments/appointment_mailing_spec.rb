# frozen_string_literal: true

require "rails_helper"

describe Domain::Appointments::AppointmentMailing do
  subject do
    klass = Class.new do
      include Domain::Appointments::AppointmentMailing

      def initialize(appointment)
        @appointment = appointment
      end
    end
    klass.new(appointment)
  end

  let(:appointment) { FactoryBot.build(:appointment, state: "requested") }
  let(:body) { double(:body, decoded: "content") }
  let(:html_part) { double(:html_part, body: body) }
  let(:mailer) { double(:mailer, deliver_now: true, subject: "some subject", html_part: html_part) }

  before do
    allow(mailer).to receive_message_chain(:body, :encoded).and_return("content")
  end

  it "#send_offer_confirmation_email" do
    expect(AppointmentMailer).to receive(:appointment_confirmation)
      .with(appointment)
      .and_return(mailer)

    expect {
      subject.send_confirmation_email
    }.to change(Interaction::Email, :count).by(1)

    interaction = Interaction::Email.last
    expect(interaction.topic).to eq appointment.appointable
    expect(interaction.direction).to eq "out"
    expect(interaction.content).to eq "content"
    expect(interaction.title).to eq mailer.subject
    expect(interaction.identifier).to eq appointment.appointable.id
    expect(interaction.admin_id).to eq appointment.appointable.admin_id
  end

  it "#send_partner_offer_confirmation_email" do
    expect(AppointmentMailer).to receive(:appointment_confirmation_for_partner_offer)
      .with(appointment)
      .and_return(mailer)
    subject.send_partner_offer_confirmation_email
  end

  describe "#send_call_appointment_confirmation_email" do
    context "with Feature APPOINTMENT_CONFIRMATION_NEW_BRANDING ON" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(Features::API_NOTIFY_PARTNERS)
          .and_return(true)

        allow(Features)
          .to receive(:active?)
          .with(Features::APPOINTMENT_CONFIRMATION_NEW_BRANDING)
          .and_return(true)
      end

      it "sends a phone call confirmation email" do
        expect(OfferMailer).to receive(:offer_appointment_confirmation_phone_call)
          .with(appointment)
          .and_return(mailer)

        expect {
          subject.send_call_appointment_confirmation_email
        }.to change(Interaction::Email, :count).by(1)

        interaction = Interaction::Email.last
        expect(interaction.topic).to eq appointment.appointable
        expect(interaction.direction).to eq "out"
        expect(interaction.content).to eq "content"
        expect(interaction.title).to eq mailer.subject
        expect(interaction.identifier).to eq appointment.appointable.id
        expect(interaction.admin_id).to eq appointment.appointable.admin_id
      end
    end

    context "with Feature APPOINTMENT_CONFIRMATION_NEW_BRANDING OFF" do
      before do
        allow(Features)
          .to receive(:active?)
          .with(Features::API_NOTIFY_PARTNERS)
          .and_return(true)

        allow(Features)
          .to receive(:active?)
          .with(Features::APPOINTMENT_CONFIRMATION_NEW_BRANDING)
          .and_return(false)
      end

      it "DOES NOT send a phone call confirmation email" do
        expect(OfferMailer).not_to receive(:offer_appointment_confirmation_phone_call)

        subject.send_call_appointment_confirmation_email
      end
    end
  end
end

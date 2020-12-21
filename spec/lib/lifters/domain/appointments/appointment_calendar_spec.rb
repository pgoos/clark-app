# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Appointments::AppointmentCalendar do
  subject do
    klass = Class.new do
      include Domain::Appointments::AppointmentCalendar

      def initialize(appointment)
        @appointment = appointment
        @appointable = appointment.appointable
      end
    end
    klass.new(appointment)
  end

  let(:appointment) { build :appointment, appointable: appointable }
  let(:appointable) { build :opportunity, category: create(:high_margin_category) }

  before do
    allow(Settings).to receive_message_chain("mailer.asset_host")
      .and_return("http://www.clark.de")
    allow(appointment).to receive(:id).and_return(1)
  end

  describe "#create_calendar_event" do
    let(:new_subject) { "New subject" }
    let(:attendee_email1) { "test_1@example.com" }
    let(:attendee_email2) { "test_2@example.com" }

    it "should generate a calendar from the appointment" do
      expect(subject.create_calendar_event).to be_kind_of(String)
    end

    it "should setup summary passed from parameters" do
      ics_content = subject.create_calendar_event(subject: new_subject)

      expect(ics_content).to include("SUMMARY:#{new_subject}")
    end

    it "should setup attendees from parameters" do
      ics_content = subject.create_calendar_event(attendee: [attendee_email1, attendee_email2])

      expect(ics_content).to include("ATTENDEE:#{attendee_email1}")
      expect(ics_content).to include("ATTENDEE:#{attendee_email2}")
    end
  end

  it "#appointment_url" do
    expect(subject.send(:appointment_url)).to eq("http://www.clark.de/de/admin/appointments/1")
  end

  it "#subject" do
    summary = subject.send(:subject)

    expect(summary).to start_with("Call")
    expect(summary).to include(appointment.mandate.full_name)
    expect(summary).to include(appointment.appointable.category.name)
  end

  it "#description" do
    mandate = appointment.mandate
    allow(mandate).to receive(:phone).and_return("xxx")

    description = subject.send(:description)
    url = subject.send(:appointment_url)

    expect(description).to include(mandate.full_name)
    expect(description).to include(mandate.phone)
    expect(description).to include(url)
  end

  context "when topic is retirement" do
    let(:appointable) { create :opportunity }

    it "#subject" do
      summary = subject.send(:subject)

      expect(summary).to start_with("Call")
      expect(summary).to include(appointment.mandate.full_name)
    end

    it "#description" do
      mandate = appointment.mandate
      allow(mandate).to receive(:phone).and_return("xxx")

      description = subject.send(:description)
      url = subject.send(:appointment_url)

      expect(description).to include(mandate.full_name)
      expect(description).to include(mandate.phone)
      expect(description).to include(url)
    end
  end
end

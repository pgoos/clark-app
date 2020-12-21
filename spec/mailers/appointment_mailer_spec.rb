# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppointmentMailer, :integration, type: :mailer do
  let!(:mandate)     { create :mandate, user: user, state: :created }
  let(:user)         { create :user, email: email, subscriber: true }
  let(:email)        { "whitfielddiffie@gmail.com" }
  let(:appointment)  { create :appointment, mandate: mandate, appointable: opportunity }
  let(:admin) { create(:admin) }
  let(:opportunity)  { create(:opportunity, admin: admin) }
  let(:documentable) { appointment.appointable }

  describe "#appointment_confirmation" do
    let(:mail) { AppointmentMailer.appointment_confirmation(appointment) }
    let(:document_type) { DocumentType.appointment_confirmation_email }

    include_examples "checks mail rendering" do
      let(:html_part) { "appointment-container" }
    end

    describe "with ahoy email tracking" do
      include_examples "checks mail rendering" do
        let(:html_part) { "appointment-container" }
      end
      include_examples "stores a message object upon delivery", "AppointmentMailer#appointment_confirmation", "appointment_mailer", "appointment_confirmation"
      include_examples "does not send out an email if mandate belongs to the partner"
      include_examples "tracks document and mandate in ahoy email"

      it "includes the tracking pixel" do
        expect(mail.body.encoded).to include("open.gif")
      end

      # TODO: get these tests to work. For some reason, this email has different encoding than the others
      it "replaces links with tracking links", skip: "failing because of encoding" do
        original_link       = "https://www.facebook.com/ClarkGermany"
        tracking_parameters = "utm_campaign=appointment_confirmation&utm_medium=email&utm_source=appointment_mailer"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{32}\/click\?signature=\w{40}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.body.encoded).to include(tracking_link)
      end

      it "has a '.ics' attachment file" do
        attachment = mail.attachments[0]

        expect(attachment).to be_a_kind_of(Mail::Part)
        expect(attachment.content_type).to eq("text/calendar")
        expect(attachment.filename).to eq("appointment.ics")
      end
    end
  end

  describe "#appointment_confirmation_for_partner_offer" do
    let(:mail) { AppointmentMailer.appointment_confirmation_for_partner_offer(appointment) }
    let(:document_type) { DocumentType.offer_appointment_confirmation_phone_call }
    let(:documentable) { appointment }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end

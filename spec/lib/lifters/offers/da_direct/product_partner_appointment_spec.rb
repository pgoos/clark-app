require 'rails_helper'
require 'lifters/offers/da_direct/product_partner_appointment'
require 'lifters/offers/da_direct/partner_appointment_message'
require 'lifters/offers/da_direct/partner_mailer'

RSpec.describe Sales::DaDirect::ProductPartnerAppointment do
  let(:mandate) { double(Mandate) }
  let(:partner) { double(Subcompany) }
  let(:partner_datum) { double(ProductPartnerDatum) }
  let(:appointment) { double(Appointment) }
  let(:message) { double(Sales::DaDirect::PartnerAppointmentMessage) }
  let(:mailer) { double(Sales::DaDirect::PartnerMailer) }

  it 'should wire the message with the mailer' do
    expect(Sales::DaDirect::PartnerAppointmentMessage).to receive(:new)
                                                              .with(mandate, partner_datum, appointment)
                                                              .and_return(message)
    expect(Sales::DaDirect::PartnerMailer).to receive(:new).with(partner).and_return(mailer)
    expect(mailer).to receive(:send_mail).with(message)
    expect(BusinessEvent).to receive(:audit).with(mandate, Sales::DaDirect::ProductPartnerAppointment::APPOINTMENT_MAIL_AUDIT_LABEL)

    subject = Sales::DaDirect::ProductPartnerAppointment.new(mandate, partner, partner_datum, appointment)
    subject.send_appointment_to_partner
  end
end

require 'rails_helper'
require 'lifters/offers/da_direct/forward_appointment_to_partner'
require 'lifters/offers/da_direct/product_partner_appointment'
require 'lifters/offers/da_direct/partner_opportunity'
require 'lifters/offers/da_direct/config'
require 'lifters/outbound_channels/mailer'

RSpec.describe Sales::DaDirect::ForwardAppointmentToPartner do
  # TODO add separate spec files for these:
  context 'inserts the partner offers into the system' # TODO move processing code from rake task sales:import_da_direct do the lifter
  context 'advises the customer' # TODO move the robo rule to send out the advices to the lifter

  context 'unit tests' do
    let(:mandate) { double(Mandate) }
    let(:opportunity) { double(Opportunity) }
    let(:partner) { double(Subcompany) }
    let(:partner_datum) { double(ProductPartnerDatum) }
    let(:appointment) { double(Appointment) }
    let(:partner_admin) { double(Admin) }

    let(:model_accessor) do
      result = OpenStruct.new
      result.mandate = mandate
      result.opportunity = opportunity
      result.partner = partner
      result.partner_datum = partner_datum
      result.appointment = appointment
      result.partner_admin = partner_admin
      result
    end

    let(:product_partner_appointment) { double(Sales::DaDirect::ProductPartnerAppointment) }
    let(:partner_opportunity) { double(Sales::DaDirect::PartnerOpportunity) }

    before :each do
      allow(Sales::DaDirect::ProductPartnerAppointment).to receive(:new)
                                                               .with(mandate, partner, partner_datum, appointment)
                                                               .and_return(product_partner_appointment)
      allow(Sales::DaDirect::PartnerOpportunity).to receive(:new)
                                                        .with(opportunity, partner_admin)
                                                        .and_return(partner_opportunity)
    end

    it 'forwards the appointments to the partner' do
      expect(appointment).to receive(:accept)
      expect(product_partner_appointment).to receive(:send_appointment_to_partner)
      expect(partner_datum).to receive(:appointment_published_to_partner)
      expect(partner_opportunity).to receive(:assign_to_partner_admin)
      expect(partner_opportunity).to receive(:change_state_to_offer_phase)
      Sales::DaDirect::ForwardAppointmentToPartner.publish_appointment_confirmation(model_accessor)
    end
  end

  context 'integration', slow: true, type: :integration do
    let(:mandate) { create(:mandate, gender: :male, state: :accepted, phone: '069 153229339') }
    let!(:user) { create(:user, email: 'test.user@test.clark.de', mandate: mandate) }
    let(:product) { create(:product, mandate: mandate, premium_price_cents: 11000, premium_price_currency: 'EUR', premium_period: :year) }
    let(:other_product) { create(:product, mandate: mandate, premium_price_cents: 11000, premium_price_currency: 'EUR', premium_period: :year) }
    let!(:opportunity) { create(:opportunity, mandate: mandate, old_product: product, state: 'initiation_phase') }
    let!(:appointment) { create(:appointment, appointable: opportunity, mandate: mandate) }
    let!(:partner) { create(:subcompany, ident: 'dadeuee1a1d') }
    let(:data_attribute) do
      {
          gender: mandate.gender,
          birthdate: mandate.birthdate.to_date,
          premium: ValueTypes::Money.new(110.00, 'EUR'),
          replacement_premium: ValueTypes::Money.new(89.00, 'EUR'),
          premium_period: :year,
          'VU' => Sales::DaDirect::Config.plan_name,
      }
    end
    let!(:partner_datum) { create(:product_partner_datum, product: product, data: data_attribute, state: 'chosen') }
    let!(:deferred_partner_datum) do
      other_data_attribute = data_attribute.dup
      other_data_attribute['VU'] = 'not chosen'
      create(:product_partner_datum, product: other_product, data: other_data_attribute, state: 'deferred')
    end
    let!(:partner_admin) { create(:admin, email: Sales::DaDirect::Config.partner_admin_emails.sample) }

    before :each do
      mailer = double(OutboundChannels::Mailer)
      expect(OutboundChannels::Mailer).to receive(:new).and_return(mailer)
      expect(mailer).to receive(:send_plain_text)
    end

    it 'integrates well for chosen data' do

      Sales::DaDirect::ForwardAppointmentModels.ready_to_publish do |models|
        Sales::DaDirect::ForwardAppointmentToPartner.publish_appointment_confirmation(models)
      end

      appointment.reload
      partner_datum.reload
      opportunity.reload

      expect(appointment).to be_accepted
      expect(partner_datum).to be_purchase_pending
      expect(opportunity.admin).to eq(partner_admin)
      expect(opportunity).to be_offer_phase
    end

    it 'integrates well for deferred data' do
      expect(deferred_partner_datum).to_not receive(:appointment_published_to_partner)

      Sales::DaDirect::ForwardAppointmentModels.ready_to_publish do |models|
        Sales::DaDirect::ForwardAppointmentToPartner.publish_appointment_confirmation(models)
      end
    end
  end
end

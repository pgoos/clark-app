require 'rails_helper'
require 'lifters/offers/da_direct/partner_opportunity'

RSpec.describe Sales::DaDirect::PartnerOpportunity do
  let(:partner_admin) { double(Admin) }
  let(:opportunity) { double(Opportunity) }

  subject { Sales::DaDirect::PartnerOpportunity.new(opportunity, partner_admin) }

  it 'should be assigned to the partner admin' do
    expect(opportunity).to receive(:update_attributes).with(admin: partner_admin)
    subject.assign_to_partner_admin
  end

  it 'should change the offer state' do
    expect(opportunity).to receive(:send_offer) # please note: nothing will be sent here, this is a legacy naming issue
    subject.change_state_to_offer_phase
  end
end
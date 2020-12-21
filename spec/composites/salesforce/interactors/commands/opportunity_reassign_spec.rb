# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/commands/opportunity_reassign"

RSpec.describe Salesforce::Interactors::Commands::OpportunityReassign, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }
  let!(:product) { create(:product) }
  let!(:offer) { create(:offer) }
  let!(:offer_option) { create(:offer_option, product: product, offer: offer) }
  let!(:opportunity) { create(:opportunity, mandate: mandate, sold_product: product, offer: offer) }
  let!(:another_admin) { create(:admin) }

  it "re assigns opportunity" do
    opportunity.assign!(another_admin)
    expect(opportunity.reload.admin_id).to eq another_admin.id
    expect(opportunity.state).to eq "initiation_phase"
    admin = create(:admin)

    object = described_class.new
    result = object.call(opportunity.id, "", { admin_email: admin.email })
    expect(result).to be_successful
    expect(opportunity.reload.admin_id).to eq admin.id
  end
end

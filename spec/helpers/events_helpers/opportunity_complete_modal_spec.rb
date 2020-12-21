# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::EventsHelper::OpportunityCompleteModal do
  subject { described_class.new(opportunity, nil) }

  let(:opportunity) { create(:opportunity_with_single_offer_option) }
  let(:product) { opportunity.offer.offer_options.first.product }

  it "calculates proper contract name" do
    expect(subject.instance_variable_get(:@products).first[:contract_name]).to eq(
      "#{product.company_name}: #{product.plan_name} (#{product.plan_ident})"
    )
  end
end

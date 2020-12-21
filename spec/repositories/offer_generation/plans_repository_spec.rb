# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferGeneration::PlansRepository, :integration do
  subject { OfferGeneration.plans_repository }

  it "should find a plan by it's ident" do
    ident = "ident#{rand}"
    plan = create(:plan, ident: ident)
    expect(subject.find_by_ident(ident)).to eq(plan)
  end
end

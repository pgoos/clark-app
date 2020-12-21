# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake offers:expires_invalid_offers", :integration, type: :task do
  it "expires the correct offers" do
    invalid_offer = create(:offer, valid_until: 20.minutes.ago, state: :active)
    valid_offer = create(:offer, valid_until: 20.minutes.from_now, state: :active)
    accepted_offer = create(:offer, valid_until: 20.minutes.ago, state: :accepted)
    rejected_offer = create(:offer, valid_until: 20.minutes.ago, state: :rejected)

    task.invoke

    expect(valid_offer.reload.state).to eq "active"
    expect(invalid_offer.reload.state).to eq "expired"
    expect(accepted_offer.reload.state).to eq "accepted"
    expect(rejected_offer.reload.state).to eq "rejected"
  end
end

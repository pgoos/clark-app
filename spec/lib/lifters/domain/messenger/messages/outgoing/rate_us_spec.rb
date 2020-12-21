# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::Messages::Outgoing::RateUs do
  let(:mandate) { build_stubbed :mandate, first_name: "John" }
  let(:admin) { build_stubbed :admin }

  it "returns built model object" do
    message = described_class.(mandate, admin)

    expect(message).to be_new_record
    expect(message.mandate).to eq mandate
    expect(message.metadata["cta_text"]).to be_present
    expect(message.metadata["push_data"]).to be_present
    expect(message.metadata["message_type"]).to eq "rate_us"
    expect(message.admin).to eq admin
    expect(message.content).to be_present
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::Messages::Outgoing::TextMessage do
  let(:mandate) { build_stubbed :mandate, first_name: "John" }
  let(:admin) { build_stubbed :admin }

  it "returns built model object" do
    message = described_class.(mandate, admin, "BLA BLA BLA")

    expect(message).to be_new_record
    expect(message.mandate).to eq mandate
    expect(message.metadata["message_type"]).to eq "text"
    expect(message.admin).to eq admin
    expect(message.content).to eq "BLA BLA BLA"
    expect(message.direction).to eq "out"
  end
end

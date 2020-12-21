# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::Messages::Outgoing::LinkMessage do
  let(:mandate) { build :mandate, first_name: "John" }
  let(:admin) { build_stubbed :admin }
  let(:linkable_type) { "Product" }
  let(:linkable_id) { "1" }

  it "returns built model object" do
    message = described_class.(mandate, admin, linkable_type, linkable_id)

    expect(message).to be_new_record
    expect(message.mandate).to eq mandate
    expect(message.admin).to eq admin
    expect(message.direction).to eq "out"
    expect(message.message_type).to eq "link"
    expect(message.linkable_type).to eq "Product"
    expect(message.linkable_id).to eq "1"
  end
end

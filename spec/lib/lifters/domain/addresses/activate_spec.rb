# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Addresses::Activate do
  subject(:activate) { described_class.new }

  let(:mandate) { object_double Mandate.new, active_address: "PREVIOUS_ADDR" }
  let(:address) { object_double Address.new, active?: false, activate!: true, mandate: mandate }

  it "activates address" do
    expect(address).to receive(:activate!)
    activate.(address)
  end

  context "when address is already active" do
    let(:address) { object_double Address.new, active?: true, activate!: true }

    it "does not activate it again" do
      expect(address).not_to receive(:activate!)
      activate.(address)
    end
  end
end

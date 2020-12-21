# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Addresses::Accept do
  subject(:accept) { described_class.new activate: activate }

  let(:activate)  { ->(input) { @activated_address = input } }
  let(:address)   { object_double Address.new, accept!: true, active_at: active_at }
  let(:active_at) { nil }
  let(:now) { Date.new(2018, 1, 4).noon }

  before do
    Timecop.freeze(now)
  end

  after do
    Timecop.return
  end

  it "accepts the address" do
    expect(address).to receive(:accept!)
    accept.(address)
  end

  context "with active_at date" do
    context "when it's in the past" do
      let(:active_at) { now - 1.day }

      it "does not activate the address" do
        accept.(address)
        expect(@activated_address).to eq address
      end
    end

    context "when it's today" do
      let(:active_at) { Time.zone.today }

      it "activates the address" do
        accept.(address)
        expect(@activated_address).to eq address
      end
    end

    context "when it's in the future" do
      let(:active_at) { Time.zone.tomorrow }

      it "does not activate the address" do
        accept.(address)
        expect(@activated_address).to be_nil
      end
    end
  end
end

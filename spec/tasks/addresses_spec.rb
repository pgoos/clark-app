# frozen_string_literal: true

require "rails_helper"

RSpec.describe "addresses:activate", type: :task do
  before { allow(Features).to receive(:active?).and_return true }

  it "activates addresses" do
    mandate1 = create :mandate, :accepted
    mandate2 = create :mandate, :created
    address1 = create :address, mandate: mandate1, active: false, active_at: 2.days.ago
    address2 = create :address, mandate: mandate1, active: false, active_at: 1.day.ago
    address3 = create :address, mandate: mandate2, active: false, active_at: 1.day.ago

    task.invoke

    expect(address1.reload).not_to be_active
    expect(address2.reload).to be_active
    expect(address3.reload).not_to be_active
  end

  context "when multiple addresses feature is disabled" do
    before { allow(Features).to receive(:active?).and_return false }

    it "activates addresses" do
      mandate = create :mandate, :accepted
      address = create :address, mandate: mandate, active: false, active_at: 2.days.ago

      task.invoke

      expect(address.reload).not_to be_active
    end
  end
end

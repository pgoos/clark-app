# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/account/repositories/device_repository"

RSpec.describe Customer::Constituents::Account::Repositories::DeviceRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#find_by_installation_id" do
    it "returns entity with aggregated data" do
      device1 = create(:device, installation_id: "FOO")
      device2 = create(:device, installation_id: "BAR")

      device = repo.find_by_installation_id("FOO")
      expect(device).not_to be_nil
      expect(device.id).to eq device1.id

      device = repo.find_by_installation_id("BAR")
      expect(device).not_to be_nil
      expect(device.id).to eq device2.id
    end
  end
end

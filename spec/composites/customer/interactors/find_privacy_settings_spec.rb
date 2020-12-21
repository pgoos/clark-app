# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/find_privacy_settings"

RSpec.describe Customer::Interactors::FindPrivacySettings, :integration do
  let(:customer) { create(:customer) }

  context "when customer has privacy settings associated" do
    let(:privacy_settings) { create(:privacy_setting, mandate_id: customer.id) }
    let(:interactor_result) {
      double(Utils::Interactor::Result.name, successful?: true, privacy_settings: privacy_settings)
    }

    before do
      allow(described_class).to receive(:call).with(customer.id).and_return(interactor_result)
    end

    it "returns privacy settings" do
      result = subject.call(customer.id)
      expect(result).to be_successful
      expect(result.privacy_settings.mandate_id).to eq customer.id
    end
  end

  context "when customer hasn\'t privacy settings associated" do
    let(:interactor_result) {
      double(Utils::Interactor::Result.name, successful?: false, errors: "Privacy Settings not found")
    }

    before do
      allow(described_class).to receive(:call).with(customer.id).and_return(interactor_result)
    end

    it "returns an error if customer doesn't exist" do
      result = subject.call(customer.id)
      expect(result).not_to be_successful
      expect(result.errors).to include "Privacy Settings not found"
    end
  end
end

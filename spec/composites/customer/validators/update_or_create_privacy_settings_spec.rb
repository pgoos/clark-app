# frozen_string_literal: true

require "rails_helper"
require "composites/customer/validators/update_or_create_privacy_settings"

RSpec.describe Customer::Validators::UpdateOrCreatePrivacySettings do
  subject(:validation) { described_class.new.call(attributes) }

  let(:attributes) { {} }

  it "every field is optional" do
    expect(validation).to be_success
  end

  context "when valid object is passed" do
    let(:attributes) { attributes_for(:privacy_setting) }

    it "returns no errors" do
      expect(validation).to be_success
    end
  end

  context "when validating third_party_tracking.enabled" do
    let(:attributes) do
      {
        third_party_tracking: {
          enabled: "NOPE",
          accepted_at: DateTime.now,
          valid_until: DateTime.now + 2.years
        }
      }
    end

    it "validates enabled as boolean" do
      expect(validation).not_to be_success
      expect(validation.errors.to_h[:third_party_tracking][:enabled])
        .to include(I18n.t("dry_validation.errors.bool?.failure"))
    end
  end

  context "when validating third_party_tracking.accepted_at" do
    let(:attributes) do
      {
        third_party_tracking: {
          enabled: true,
          accepted_at: "now",
          valid_until: DateTime.now + 2.years
        }
      }
    end

    it "validates accepted_at as date_time" do
      expect(validation).not_to be_success
      expect(validation.errors.to_h[:third_party_tracking][:accepted_at])
        .to include(I18n.t("dry_validation.errors.date_time?.failure"))
    end
  end

  context "when validating third_party_tracking.valid_until" do
    let(:attributes) do
      {
        third_party_tracking: {
          enabled: true,
          accepted_at: DateTime.now,
          valid_until: "2077"
        }
      }
    end

    it "validates accepted_at as date_time" do
      expect(validation).not_to be_success
      expect(validation.errors.to_h[:third_party_tracking][:valid_until])
        .to include(I18n.t("dry_validation.errors.date_time?.failure"))
    end
  end
end

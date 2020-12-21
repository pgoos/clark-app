# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Interactors::UpdateOrCreatePrivacySettings do
  subject(:update_or_create) do
    described_class.new(
      privacy_settings_repo: privacy_settings_repo,
      validate: Customer::Validators::UpdateOrCreatePrivacySettings.new
    )
  end

  let(:mandate) { build_stubbed(:mandate) }
  let(:customer_id) { mandate.id }

  let(:privacy_settings_repo_class) { Customer::Repositories::PrivacySettingsRepository }
  let(:privacy_settings_repo_response) { Customer::Entities::PrivacySettings.new(privacy_settings_attributes) }
  let(:privacy_settings_attributes) { build_stubbed(:privacy_setting, mandate: mandate).attributes.symbolize_keys }
  let(:found_entity) { privacy_settings_repo_response }
  let(:privacy_settings_repo) do
    instance_double(
      privacy_settings_repo_class,
      update: privacy_settings_repo_response,
      create: privacy_settings_repo_response,
      find_by: found_entity
    )
  end

  before do
    allow(privacy_settings_repo_class).to receive(:new).and_return(privacy_settings_repo)
  end

  context "when attributes are valid" do
    let(:accepted_at) { DateTime.now }

    let(:attributes) do
      HashWithIndifferentAccess.new(
        {
          third_party_tracking: {
            enabled: true,
            accepted_at: accepted_at.to_s
          }
        }
      )
    end

    it "updates privacy_settings with normalized attributes" do
      expect(privacy_settings_repo).to(
        receive(:update).with(
          privacy_settings: privacy_settings_repo_response,
          attributes: { third_party_tracking: { enabled: true, accepted_at: accepted_at } }
        )
      )
      result = update_or_create.(customer_id, attributes)
      expect(result).to be_success
    end

    context "when previous privacy_settings does not exist" do
      let(:found_entity) { nil }

      it "creates privacy_settings with normalized attributes" do
        expect(privacy_settings_repo).to(
          receive(:create).with(
            customer_id: customer_id,
            attributes: { third_party_tracking: { enabled: true, accepted_at: accepted_at } }
          )
        )
        result = update_or_create.(customer_id, attributes)
        expect(result).to be_success
      end
    end
  end

  context "when attributes are invalid" do
    let(:attributes) do
      HashWithIndifferentAccess.new(
        {
          third_party_tracking: {
            enabled: "NOPE",
            accepted_at: "some_day"
          }
        }
      )
    end

    it "returns failure" do
      result = update_or_create.(customer_id, attributes)
      expect(result).to be_failure
    end
  end
end

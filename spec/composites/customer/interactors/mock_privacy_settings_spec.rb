# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Interactors::MockPrivacySettings do
  subject(:mock) do
    described_class.new(
      privacy_settings_repo: privacy_settings_repo,
      validate: Customer::Validators::UpdateOrCreatePrivacySettings.new
    )
  end

  let(:privacy_settings_repo_class) { Customer::Repositories::PrivacySettingsRepository }
  let(:privacy_settings_repo_response) { Customer::Entities::PrivacySettings.new(privacy_settings_attributes) }
  let(:privacy_settings_attributes) { build_stubbed(:privacy_setting, mandate_id: 0).attributes.symbolize_keys }
  let(:found_entity) { privacy_settings_repo_response }
  let(:privacy_settings_repo) do
    instance_double(
      privacy_settings_repo_class,
      mock: privacy_settings_repo_response
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

    it "mock privacy_settings with normalized attributes" do
      expect(privacy_settings_repo).to(
        receive(:mock).with(
          attributes: { third_party_tracking: { enabled: true, accepted_at: accepted_at } }
        )
      )
      result = mock.(attributes)
      expect(result).to be_success
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
      result = mock.(attributes)
      expect(result).to be_failure
    end
  end
end

# frozen_string_literal: true

require "rails_helper"
require "composites/customer/repositories/privacy_settings_repository"

RSpec.describe Customer::Repositories::PrivacySettingsRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate) }

  describe "#find_by" do
    before do
      create(:privacy_setting, mandate: mandate)
    end

    it "returns entity with aggregated data" do
      privacy_settings = repo.find_by(customer_id: mandate.id)

      expect(privacy_settings).to be_kind_of Customer::Entities::PrivacySettings
      expect(privacy_settings.customer_id).to eq mandate.id
      expect(privacy_settings.third_party_tracking).to eq mandate.privacy_setting.third_party_tracking
    end

    context "when privacy_settings does not exist" do
      it "returns nil" do
        expect(repo.find_by(customer_id: 999)).to be_nil
      end
    end

    context "when not wrapping with entity" do
      it "returns ActiveRecord result" do
        privacy_settings = repo.find_by(customer_id: mandate.id, as_entity: false)

        expect(privacy_settings).to be_kind_of ::PrivacySetting
      end
    end
  end

  describe "#update" do
    let(:privacy_settings) { create(:privacy_setting, :third_party_tracking_disabled, mandate: mandate) }
    let(:valid_until) { 2.years.from_now }
    let(:attributes) do
      {
        third_party_tracking: {
          enabled: true,
          accepted_at: Time.current,
          valid_until: valid_until
        }
      }
    end

    it "updates passed privacy_settings" do
      repo.update(privacy_settings: privacy_settings, attributes: attributes)

      expect(privacy_settings.reload.third_party_tracking["enabled"]).to eq true
    end

    it "returns privacy_settings entity" do
      repo_response = repo.update(privacy_settings: privacy_settings, attributes: attributes)

      expect(repo_response).to be_kind_of Customer::Entities::PrivacySettings
    end

    context "when not passing third_party_tracking ttl info" do
      let(:valid_until) { nil }

      it "sets valid_until to default (from Settings)" do
        repo.update(privacy_settings: privacy_settings, attributes: attributes)

        expect(privacy_settings.reload.third_party_tracking["valid_until"]).not_to be_nil
      end
    end
  end

  describe "#create" do
    let(:valid_until) { 2.years.from_now }
    let(:attributes) { attributes_for(:privacy_setting) }

    it "creates privacy_settings" do
      privacy_settings = repo.create(customer_id: mandate.id, attributes: attributes)

      expect(privacy_settings.id).not_to be_nil
    end

    context "when not passing third_party_tracking ttl info" do
      let(:attributes) do
        {
          third_party_tracking: {
            enabled: true,
            accepted_at: Time.current,
            valid_until: nil
          }
        }
      end

      it "sets valid_until to default (from Settings)" do
        privacy_settings = repo.create(customer_id: mandate.id, attributes: attributes)

        expect(privacy_settings.third_party_tracking["valid_until"]).not_to be_nil
      end

      it "returns privacy_settings entity" do
        repo_response = repo.create(customer_id: mandate.id, attributes: attributes)

        expect(repo_response).to be_kind_of Customer::Entities::PrivacySettings
      end
    end
  end

  describe "#mock" do
    let(:valid_until) { 2.years.from_now }
    let(:attributes) { attributes_for(:privacy_setting) }

    it "mocks privacy_settings" do
      privacy_settings = repo.mock(attributes: attributes)

      expect { privacy_settings }.not_to change(PrivacySetting, :count)
    end

    context "when not passing third_party_tracking ttl info" do
      let(:attributes) do
        {
          third_party_tracking: {
            enabled: true,
            accepted_at: Time.current,
            valid_until: nil
          }
        }
      end

      it "sets valid_until to default (from Settings)" do
        privacy_settings = repo.mock(attributes: attributes)

        expect(privacy_settings.third_party_tracking["valid_until"]).not_to be_nil
      end

      it "returns privacy_settings entity" do
        repo_response = repo.mock(attributes: attributes)

        expect(repo_response).to be_kind_of Customer::Entities::PrivacySettings
      end
    end
  end
end

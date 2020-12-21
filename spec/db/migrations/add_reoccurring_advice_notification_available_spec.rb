# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "add_reoccurring_advice_notification_available"

describe AddReoccurringAdviceNotificationAvailable do
  let(:identifier) { "email-mandate_mailer-reoccurring_advice_notification_available" }

  before do
    Comfy::Cms::Site.create!(label: "de", locale:   "de", identifier: "test_site",
                             path: "site", hostname: "clark.fake")
  end

  describe "#data" do
    it "creates a snippet" do
      described_class.new.data
      expect(Comfy::Cms::Snippet.find_by(identifier: identifier)).to be_instance_of Comfy::Cms::Snippet
    end
  end

  describe "#rollback" do
    it "does not raise an exception" do
      described_class.new.data
      described_class.new.rollback

      expect(Comfy::Cms::Snippet.find_by(identifier: identifier)).to be_nil
    end
  end
end

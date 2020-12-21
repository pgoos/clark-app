# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messenger Text Spec" do
  # Checks whether correct file is picked up for Messenger text when in Clark context
  context "Clark" do
    it "reads the messenger strings from correct file" do
      expect(I18n.t("messenger.inquiry_cancellation_plural.content")).to eq("Hallo %{name},\nes gibt wichtige Neuigkeiten zu deinen folgenden Verträgen im Bereich %{category_names}. Schau doch gleich mal in deinem Clark-Account nach.\n")
      I18n.t("messenger.waiting_time_satisfaction_message.content").include?("Clark")
    end
  end
end

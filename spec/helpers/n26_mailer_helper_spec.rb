# frozen_string_literal: true

require "rails_helper"

RSpec.describe N26MailerHelper, type: :helper do
  let(:migration_token) { SecureRandom.alphanumeric(16) }

  describe "#build_migration_path" do
    before do
      stub_const("N26MailerHelper::MIGRATION_PATH", "/skirnir?migration_token=$token_value$")
    end

    it "builds migration path by replacing token" do
      expect(build_migration_path(migration_token)).to eq("http://test.host/de/skirnir?migration_token=#{migration_token}")
    end
  end
end

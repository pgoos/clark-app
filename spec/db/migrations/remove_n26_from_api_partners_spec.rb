# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "remove_n26_from_api_partners"

RSpec.describe RemoveN26FromApiPartners, :integration do
  describe "#data" do
    before do
      create :api_partner, partnership_ident: described_class::PARTNERSHIP_IDENT
      described_class.new.data
    end

    it "deletes API partner with n26 partner ident" do
      expect(ApiPartner.where(partnership_ident: described_class::PARTNERSHIP_IDENT)).to be_empty
    end
  end
end

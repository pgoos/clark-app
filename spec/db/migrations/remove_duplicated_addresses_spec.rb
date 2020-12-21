# frozen_string_literal: true

require "rails_helper"

require Rails.root.join "db", "migrate", "20190425173229_remove_duplicated_addresses"

RSpec.describe RemoveDuplicatedAddresses do
  let(:migrate) { described_class.new }
  let(:active_address) { create(:address) }
  let(:mandate) { create(:mandate, :accepted, active_address: active_address) }

  describe "#change" do
    describe "remove duplacations" do
      context "when address is not accepted and not active" do
        before { create(:address, accepted: false, active: false, mandate: mandate) }

        it "removes it" do
          expect { migrate.change }.to change(mandate.addresses, :count).from(2).to(1)
        end

        it "keeps only the active_address" do
          active_address = mandate.active_address

          expect(active_address).not_to be_nil
        end
      end
    end
  end
end

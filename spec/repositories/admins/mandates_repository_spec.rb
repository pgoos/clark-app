# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admins::MandatesRepository, :integration do
  before { Time.zone = "UTC" }

  subject(:repo) { described_class.new admin, Mandate.all }

  let(:admin) { create :admin }
  let(:role)  { admin.role }

  describe "#all" do
    it "returns relation object" do
      expect(repo.all).to be_kind_of "Mandate::ActiveRecord_Relation".constantize
    end

    context "with scope authorizations" do
      let!(:clark_vip_mandate) { create :mandate, :owned_by_clark, :vip }
      let!(:clark_critic_mandate) { create :mandate, :owned_by_clark, :critic }
      let!(:n26_vip_mandate) { create :mandate, :owned_by_n26, :vip }
      let!(:clark_mandate) { create :mandate, :owned_by_clark }

      before do
        create :scope_authorization, :mandates_owner, value: "n26"
        create :scope_authorization, :mandates_variety, value: "critic"

        authorization_owner_clark    = create :scope_authorization, :mandates_owner, value: "clark"
        authorization_variety_vip    = create :scope_authorization, :mandates_variety, value: "vip"
        authorization_variety_blank  = create :scope_authorization, :mandates_variety, value: nil

        create :scope_role_authorization, role: role, scope_authorization: authorization_owner_clark
        create :scope_role_authorization, role: role, scope_authorization: authorization_variety_vip
        create :scope_role_authorization, role: role, scope_authorization: authorization_variety_blank
      end

      it "filters out mandates according to authorization rules" do
        expect(repo.all).to match_array [clark_vip_mandate, clark_mandate]
      end

      context "with ewe_datum visibility setting set false" do
        before { allow(Settings).to receive_message_chain("admin.mandate.index.ewe_datum").and_return(false) }

        it "does not includes mandate document attributes" do
          create :document, :cover_note, documentable: clark_vip_mandate
          create :document, :mandate_document_biometric, documentable: clark_mandate

          expect(repo.all).to match_array [clark_vip_mandate, clark_mandate]
          repo.all.each { |el| expect(el).not_to respond_to(:ewe_datum) }
        end
      end
    end

    context "when revoked and unrevoked mandates exists" do
      let!(:mandate) { create(:mandate) }
      let!(:revoked_mandate) { create(:mandate, :revoked) }

      context "when admin without permission to see revoked mandate calls method" do
        it "does not return revoked mandate" do
          mandates = repo.all

          expect(mandates.count).to eq(1)
          expect(mandates).to match_array [mandate]
        end
      end

      context "when admin with permission to see revoked mandates calls method" do
        let!(:view_revoked_mandates) { create(:permission, :view_revoked_mandates) }
        let!(:permit_admin) { admin.permissions << view_revoked_mandates }

        it "does return revoked mandate" do
          expect(repo.all).to match_array [mandate, revoked_mandate]
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe OutboundChannels::DeliveryPermission do
  let(:subject) { described_class.new }
  let(:mandate) { create :mandate }

  describe "#check_owner_privileges" do
    context "when the mandate belongs to clark" do
      before { mandate.update(owner_ident: "clark") }

      it "should allow interaction" do
        expect(subject.interaction_allowed_for?(mandate)).to eq(true)
      end
    end

    context "when the mandate belongs to a partner" do
      context "partner is active" do
        let(:partner) { (create :partner, :active) }

        before { mandate.update(owner_ident: partner.ident) }

        it "should allow interaction" do
          expect(subject.interaction_allowed_for?(mandate)).to eq(true)
        end
      end

      context "partner is inactive" do
        let(:partner) { (create :partner, :inactive) }

        before { mandate.update(owner_ident: partner.ident) }

        it "should allow interaction" do
          expect(subject.interaction_allowed_for?(mandate)).to eq(false)
        end
      end
    end
  end
end

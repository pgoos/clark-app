# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Owners do
  let!(:active_partner) { create(:partner, :active) }
  let!(:inactive_partner) { create(:partner, :inactive) }

  describe ".active_partner_idents" do
    it "should return active partner idents" do
      expect(described_class.active_partner_idents).to eq([active_partner.ident])
    end
  end

  describe ".active_idents" do
    it "should return clark ident along with active partner idents" do
      expect(described_class.active_idents).to match_array([Domain::Owners::CLARK_IDENT, active_partner.ident])
    end
  end

  describe ".active?" do
    context "partner is active" do
      it "should return true" do
        expect(described_class.active?(active_partner.ident)).to eq(true)
      end
    end

    context "partner is inactive" do
      it "should return false" do
        expect(described_class.active?(inactive_partner.ident)).to eq(false)
      end
    end
  end

  describe ".inactive?" do
    context "partner is active" do
      it "should return false" do
        expect(described_class.inactive?(active_partner.ident)).to eq(false)
      end
    end

    context "partner is inactive" do
      it "should return true" do
        expect(described_class.inactive?(inactive_partner.ident)).to eq(true)
      end
    end
  end

  describe ".get" do
    context "owner is active" do
      it "should return respective owner class for the given ident" do
        expect(described_class.get(Domain::Owners::CLARK_IDENT)).to eq(Domain::Owners::Clark)
      end

      it "should return NoOwner class if ident is blank" do
        expect(described_class.get("")).to eq(Domain::Owners::NoOwner)
      end

      it "should return NoOwner class if no owner class found" do
        expect(described_class.get(active_partner.ident)).to eq(Domain::Owners::NoOwner)
      end
    end

    context "owner is inactive" do
      it "should return  NoOwner class" do
        expect(described_class.get(active_partner.ident)).to eq(Domain::Owners::NoOwner)
      end
    end
  end
end

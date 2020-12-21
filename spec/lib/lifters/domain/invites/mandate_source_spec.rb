# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Invites::MandateSource do
  let(:malburg) { create(:partner, :active, ident: Domain::Owners::MALBURG_IDENT) }
  let(:clark) { create(:partner, :active, ident: Domain::Owners::CLARK_IDENT) }
  let(:communikom) { create(:partner, :active, ident: Domain::Owners::COMMUNIKOM_IDENT) }
  let(:zvo) { create(:partner, :active, ident: Domain::Owners::ZVO_IDENT) }
  let(:malburg_source) { {anonymous_lead: true, adjust: {"network": "Malburg", "campaign": "Call"}} }
  let(:clark_source) { {anonymous_lead: true, adjust: {"network": "fb-malburg"}} }
  let(:communikom_source) { {anonymous_lead: true, adjust: {"network": "Communikom"}} }
  let(:zvo_source) { {anonymous_lead: true, adjust: {"network": "Zvo"}} }
  let(:no_ident) { {anonymous_lead: true} }

  describe ".get_source_based_on_owner" do
    it "returns valid source json if owner ident is malburg" do
      expect(described_class.get_source_based_on_owner(malburg.ident)).to eq(malburg_source)
    end

    it "returns valid source json if owner ident is clark" do
      expect(described_class.get_source_based_on_owner(clark.ident)).to eq(clark_source)
    end

    it "returns valid source json if no ident specified" do
      expect(described_class.get_source_based_on_owner("")).to eq(no_ident)
    end

    it "returns valid source json if owner ident is communikom" do
      expect(described_class.get_source_based_on_owner(communikom.ident)).to eq(communikom_source)
    end

    it "returns valid source json if owner ident is zvo" do
      expect(described_class.get_source_based_on_owner(zvo.ident)).to eq(zvo_source)
    end
  end
end

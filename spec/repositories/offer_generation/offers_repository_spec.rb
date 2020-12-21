# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferGeneration::OffersRepository, :integration do
  subject { OfferGeneration.offers_repository }

  context "when the offer is created" do
    it "should save an offer" do
      offer = build(:offer)
      subject.create_and_send(offer)
      expect(offer).not_to be_new_record
    end
  end

  context "when the offer is sent" do
    it "should send the offer and update states accordingly" do
      offer = build(:offer)

      subject.create_and_send(offer)
      offer.reload

      expect(offer).to be_active
      expect(offer).not_to be_new_record
      expect(offer.opportunity).to be_offer_phase
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::MilesMoreWelcomeBooking do
  subject { described_class.new(mandate) }
  let(:mandate) do
    instance_double(
      Mandate,
      mam_enabled?:     true,
      tos_accepted_at:  Time.zone.now.advance(days: -1),
      mam_member_alias: member_alias,
      accepted?:        true
    )
  end
  let(:cipher) { (0..9).to_a.sample }
  let(:member_alias) { "99222302063283#{cipher}" } # checked it with real data: String
  let(:secure_token) { SecureRandom.hex(10) }

  context "booking values" do
    it "should book 1000 miles" do
      expect(subject.miles_to_book).to eq(1000)
    end

    it "has the correct transaction_text" do
      allow(SecureRandom).to receive(:hex).with(10).and_return(secure_token)
      expect(subject.transaction_text).to eq(secure_token)
    end

    it "should provide a transaction_text of max 20 characters size" do
      expect(subject.transaction_text.size <= 20).to be_truthy
    end

    it "should provide a property code" do
      expect(subject.mam_property_code).to eq("M3037")
    end

    it "should delegate to the member alias" do
      expect(subject.member_alias).to eq(member_alias)
    end

    it "should be a creational booking action" do
      expect(subject.action).to eq("C")
    end

    it "should provide an empty additional partner data" do
      expect(subject.additional_partner_data).to eq("{}")
    end
  end

  context "allow or not allow booking", type: :integration do
    let(:mandate) { create(:mandate, :mam_with_status, :accepted) }

    context "#already_booked?" do
      it "should be true, if there is a loyalty booking" do
        create(:loyalty_booking, mandate: mandate, bookable: mandate)
        expect(subject).to be_already_booked
      end

      it "should be false, if there is no loyalty booking" do
        expect(subject).not_to be_already_booked
      end
    end

    context "#valid?" do
      let(:user) { create(:user) }
      let(:non_mam_mandate) { create(:mandate, :accepted, user: user) }

      it "should be valid for a mam mandate without booking" do
        expect(subject).to be_valid
      end

      it "should not be valid for a non mam mandate" do
        expect(described_class.new(non_mam_mandate)).not_to be_valid
      end

      it "should not be valid, if a mandate is not accepted" do
        expect(described_class.new(Mandate.new(user: User.new))).not_to be_valid
      end

      it "should not be valid, if the accepted date is younger than 24h" do
        not_old_enough = Time.zone.now.advance(days: -1, minutes: 1)
        mandate.tos_accepted_at = not_old_enough
        expect(subject).not_to be_valid
      end

      it "should not be valid, if the tos_accepted_at is not set" do
        mandate.tos_accepted_at = nil
        expect(subject).not_to be_valid
      end
    end
  end

  context "perform the booking locally" do
    before do
      allow(LoyaltyBooking).to receive_message_chain(:find_by, :present?).and_return(false)
    end

    it { is_expected.to be_valid }

    it "should create a loyalty_booking" do
      expect(LoyaltyBooking).to receive(:create!).with(
        mandate:  mandate,
        bookable: mandate,
        kind:     :mam,
        amount:   1000
      )
      subject.create_loyalty_booking!
    end

    it "should NOT create a loyalty_booking if invalid" do
      allow(mandate).to receive(:mam_enabled?).and_return(false)
      expect {
        subject.create_loyalty_booking!
      }.to raise_error("Cannot book an invalid booking!")
    end

    it "should NOT create a loyalty_booking if already booked" do
      allow(LoyaltyBooking).to receive_message_chain(:find_by, :present?).and_return(true)
      expect {
        subject.create_loyalty_booking!
      }.to raise_error("Existing loyalty booking found!")
    end
  end
end

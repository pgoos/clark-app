# frozen_string_literal: true

require "rails_helper"
require "lifters/domain/partners/mocks/fake_miles_more_client"

RSpec.describe Domain::Partners::MilesMore do
  subject { described_class.new(mandate) }

  let(:mandate) { create(:mandate, :mam, state: :accepted) }
  let(:mandate_with_full_mam_data) { create(:mandate, :mam_with_status, state: :accepted, tos_accepted_at: Date.today) }
  let(:member_alias) { "1234567890" }
  let(:now) { Time.zone.parse("Wed, 26 Sep 2018 08:00:00 CEST +02:00") }

  before { Timecop.freeze(now) }

  after { Timecop.return }

  it "should raise if the mandate is invalid" do
    mandate = instance_double(Mandate, valid?: false)
    validation_error_message = "mandate invalid"
    allow(mandate).to receive_message_chain(:errors, :full_messages, :join).with(", ").and_return(validation_error_message)

    expect {
      described_class.new(mandate)
    }.to raise_error("Mandate invalid: '#{validation_error_message}'!")
  end

  describe "#authenticated_request_token" do
    it "returns an authenticated request token" do
      expect(subject.authenticated_request_token).not_to be_blank
    end
  end

  describe "#member_status" do
    it "should accept a Fixnum" do
      integer = Integer(member_alias)
      cleaned = Domain::Partners::MilesMore.cleanup_alias(integer)
      expect(cleaned).to eq(member_alias)
    end

    it "should accept a string with white space" do
      with_white_space = " #{member_alias} "
      cleaned = Domain::Partners::MilesMore.cleanup_alias(with_white_space)
      expect(cleaned).to eq(member_alias)
    end

    it "knows that it was successful" do
      response = subject.member_status(member_alias)
      expect(response[:success]).to be(true)
    end

    it "refuses an invalid mmAccountNumber" do
      response = subject.member_status(Domain::Partners::Mocks::FakeMilesMoreClient.invalid_mam_account_number)
      expect(response[:success]).to be(false)
    end

    it "returns a valid user overview" do
      response = subject.member_status(member_alias)
      expect(response[:data]["mmAccountNumber"]).to eq(member_alias)
    end

    it "gives error information for an invalid mmAccountNumber" do
      response = subject.member_status(Domain::Partners::Mocks::FakeMilesMoreClient.invalid_mam_account_number)
      expect(response[:errors]).not_to be_empty
    end
  end

  describe "#credit_miles" do
    it "books miles as expected", type: :integration do
      mam_loyalty_group = create(:mam_loyalty_group, default_fallback: true)
      create(:mam_payout_rule, products_count: 1, base: 150, mam_loyalty_group: mam_loyalty_group)
      create(:mam_payout_rule, products_count: 2, base: 1000, mam_loyalty_group: mam_loyalty_group)
      create(:product, state: :details_available, mandate: mandate_with_full_mam_data)
      create(:product, state: :details_available, mandate: mandate_with_full_mam_data)
      mandate.save
      mam = described_class.new(mandate_with_full_mam_data)
      mam.credit_miles
      expect(LoyaltyBooking.count).to eq(2)
      expect(LoyaltyBooking.first.amount).to eq(150)
      expect(LoyaltyBooking.last.amount).to eq(1000)
    end
  end

  describe "#update_miles_more_data!" do
    let(:error_message) { I18n.t("account.wizards.mam.error") }

    it "can update_miles_and_more_data! and gets mam enabled (no prior mam data)" do
      result = subject.update_miles_more_data!(member_alias)
      expect(result[:success]).to be(true)
      expect(mandate.loyalty["mam"]["mmAccountNumber"]).to eq(member_alias)
    end

    it "is invoked without member on mam enabled user with mam data" do
      mam    = described_class.new(mandate_with_full_mam_data)
      result = mam.update_miles_more_data!
      expect(result[:success]).to be(true)
    end

    it "has a card number error message" do
      old_locale = I18n.locale
      I18n.locale = :de
      expect(error_message).not_to match(/translat/)
      I18n.locale = old_locale
    end

    it "may be invoked with nil and return a result not successful" do
      result = subject.update_miles_more_data!(nil)
      expect(result[:success]).to be(false)
    end

    it "may be invoked with nil and return an error" do
      result = subject.update_miles_more_data!(nil)
      expect(result[:errors]).to eq(mam: {error: error_message})
    end

    it "may be invoked with '' and return a result not successful" do
      result = subject.update_miles_more_data!("")
      expect(result[:success]).to be(false)
    end

    it "may be invoked with '' and return a result not successful" do
      result = subject.update_miles_more_data!("")
      expect(result[:errors]).to eq(mam: {error: error_message})
    end

    it "will raise an error if the mam account number is already used" do
      create(:mandate, :accepted, :mam_with_status, mmAccountNumber: member_alias)
      result = subject.update_miles_more_data!(member_alias)
      expect(result[:errors]).to eq(mam: {error: error_message})
    end
  end

  describe "#update_card_number!" do
    context "when the card number is valid" do
      it "returns a response object with success state" do
        result = subject.update_card_number!("1234")
        expect(result.success?).to be(true)
      end
    end

    context "when the card number is invalid" do
      let(:invalid_card_number) { Domain::Partners::Mocks::FakeMilesMoreClient.invalid_mam_account_number }
      let(:error_msg) { "Validation Error: Card number is invalid: #{invalid_card_number}" }

      it "returns a response objecg with invalid state" do
        result = subject.update_card_number!(invalid_card_number)
        expect(result.success?).to be(false)
        expect(result.error).to eq(error_msg)
      end
    end

    context "when the card number is duplicate" do
      let(:error_msg) { I18n.t("account.wizards.mam.error") }
      let!(:existing_mandate) { create(:mandate, :accepted, :mam_with_status, mmAccountNumber: "1234") }

      context "when the mandate is accepted" do
        it "does not let the card number to be updated" do
          result = subject.update_card_number!("1234")
          expect(result.success?).to be(false)
          expect(result.error).to eq(error_msg)
        end
      end

      context "when the mandate is not accepted" do
        it "lets the card number to be updated" do
          existing_mandate.state = "in_creation"
          existing_mandate.save!
          result = subject.update_card_number!("1234")
          expect(result.success?).to be(true)
        end
      end
    end

    context "when the card number is empty" do
      let(:error_msg) { I18n.t("account.wizards.mam.error") }

      it "returns a respons eobject with invalid state" do
        result = subject.update_card_number!("")
        expect(result.success?).to be(false)
        expect(result.error).to eq(error_msg)
      end
    end
  end
end

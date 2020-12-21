# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Constituents::UpgradeJourney::Interactors::ConfirmSignature do
  subject(:confirm) do
    described_class.new(
      customer_repo: customer_repo,
      download_signature: download_signature,
      redeem_voucher: redeem_voucher
    )
  end

  let(:customer_id) { 999 }
  let(:customer_repo) { double :repo, find: customer, update!: true, create_signature!: true }
  let(:updated_customer) { double :customer }

  let(:download_signature) do
    lambda do |_|
      double(
        :result,
        failure?: false,
        pdf_with_biodata: "PDF_WITH_BIODATA",
        pdf_without_biodata: "PDF_WITHOUT_BIODATA",
        png_signature: "PNG_SIGNATURE"
      )
    end
  end

  let(:redeem_voucher) do
    lambda do |_|
      double(
        :result,
        successful?: true
      )
    end
  end

  let(:customer) do
    double(
      :customer,
      upgrade_journey_state: "signature",
      mandate_state: "in_creation",
      customer_state: "self_service"
    )
  end

  it "updates customer states and attributes" do
    Timecop.freeze(Time.zone.now)
    expect(customer_repo).to receive(:update!).with(
      customer_id,
      tos_accepted_at: Time.zone.now,
      confirmed_at: Time.zone.now,
      health_consent_accepted_at: Time.zone.now,
      upgrade_journey_state: "finished",
      mandate_state: "created",
      customer_state: "mandate_customer"
    )
    expect(customer_repo).to receive(:find).and_return(customer, updated_customer)
    result = confirm.(customer_id, "INSIGN_SESSION_ID")
    expect(result).to be_successful
    expect(result.customer).to eq updated_customer
  end

  it "downloads signature and saves it to customer" do
    expect(customer_repo).to receive(:create_signature!).with(
      customer_id,
      "PDF_WITH_BIODATA",
      "PDF_WITHOUT_BIODATA",
      "PNG_SIGNATURE"
    )
    confirm.(customer_id, "INSIGN_SESSION_ID")
  end

  it "redeems voucher for costumer" do
    expect(redeem_voucher).to receive(:call).with(customer_id)

    confirm.(customer_id, "INSIGN_SESSION_ID")
  end

  context "when the download of signature fails" do
    let(:download_signature) do
      lambda do |_|
        double(
          :result,
          failure?: true,
          errors: ["DOWNLOAD ERROR"]
        )
      end
    end

    it "returns failure" do
      result = confirm.(customer_id, "INSIGN_SESSION_ID")
      expect(result).to be_failure
      expect(result.errors).to eq ["DOWNLOAD ERROR"]
    end
  end

  context "when customer does not exist" do
    let(:customer_repo) { double :repo, find: nil }

    it "returns failure" do
      result = confirm.(customer_id, "INSIGN_SESSION_ID")
      expect(result).to be_failure
    end
  end
end

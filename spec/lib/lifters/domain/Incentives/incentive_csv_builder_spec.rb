# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Incentives::IncentiveCsvBuilder do
  let(:subject) { described_class.new }

  let!(:mandate_one) { create(:mandate, user: create(:user)) }
  let!(:mandate_two) { create(:mandate, user: create(:user)) }
  let!(:mandate_three) { create(:mandate, user: create(:user)) }

  let(:expected_csv_with_price_true) do
    <<~CSV
      ID,Name,IBAN des Beguenstigten,BIC des Beguenstigten,Network,Betrag
      #{mandate_one.id},#{mandate_one.full_name},#{mandate_one.iban_for_display(true)},#{mandate_one.bic_code},#{mandate_one.source},
      #{mandate_two.id},#{mandate_two.full_name},#{mandate_two.iban_for_display(true)},#{mandate_two.bic_code},#{mandate_two.source},
      #{mandate_three.id},#{mandate_three.full_name},#{mandate_three.iban_for_display(true)},#{mandate_three.bic_code},#{mandate_three.source},
    CSV
  end

  let(:expected_csv_with_price) do
    <<~CSV
      ID,Name,IBAN des Beguenstigten,BIC des Beguenstigten,Network,Betrag
      #{mandate_one.id},#{mandate_one.full_name},#{mandate_one.iban_for_display(true)},#{mandate_one.bic_code},#{mandate_one.source},50
      #{mandate_two.id},#{mandate_two.full_name},#{mandate_two.iban_for_display(true)},#{mandate_two.bic_code},#{mandate_two.source},50
      #{mandate_three.id},#{mandate_three.full_name},#{mandate_three.iban_for_display(true)},#{mandate_three.bic_code},#{mandate_three.source},50
    CSV
  end

  let(:expected_csv_with_price_false) do
    <<~CSV
      ID,Name,IBAN des Beguenstigten,BIC des Beguenstigten,Network
      #{mandate_one.id},#{mandate_one.full_name},#{mandate_one.iban_for_display(true)},#{mandate_one.bic_code},#{mandate_one.source}
      #{mandate_two.id},#{mandate_two.full_name},#{mandate_two.iban_for_display(true)},#{mandate_two.bic_code},#{mandate_two.source}
      #{mandate_three.id},#{mandate_three.full_name},#{mandate_three.iban_for_display(true)},#{mandate_three.bic_code},#{mandate_three.source}
    CSV
  end

  let(:empty_csv) do
    <<~CSV
      ID,Name,IBAN des Beguenstigten,BIC des Beguenstigten,Network,Betrag
    CSV
  end

  context ".create_csv" do
    context "with default values" do
      it "creates an empty csv" do
        csv = subject.create_csv([mandate_one, mandate_two, mandate_three])
        expect(csv).to eq(empty_csv)
      end
    end

    context "when partner is present with price" do
      before do
        mandate_one.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_two.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_three.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_one.user.save!
        mandate_two.user.save!
        mandate_three.user.save!
      end

      it "creates the csv with the price" do
        csv = subject.create_csv([mandate_one, mandate_two, mandate_three], partner: "referral program")
        expect(csv).to eq(expected_csv_with_price)
      end

      context "when the returned price to pay is 0" do
        before do
          allow(subject).to receive(:get_payout_price).and_return(0)
        end

        it "does not include the row in the payout" do
          csv = subject.create_csv([mandate_one, mandate_two, mandate_three], partner: "referral program")
          expect(csv).to eq(empty_csv)
        end
      end
    end

    context "when price is set to false" do
      before do
        mandate_one.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_two.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_three.user.source_data = {adjust: {network: "Referral Program"}}
        mandate_one.user.save!
        mandate_two.user.save!
        mandate_three.user.save!
      end

      it "creates csv without price column" do
        csv = subject.create_csv([mandate_one, mandate_two, mandate_three], show_price: false, partner: "referral program")
        expect(csv).to eq(expected_csv_with_price_false)
      end
    end

    context "when no mandate is present" do
      it "returns an empty csv" do
        csv = subject.create_csv(nil)
        expect(csv).to eq(empty_csv)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Situations::RetirementSituation do
  subject(:situation) { Domain::Situations::RetirementSituation.new mandate }

  let(:mandate) { object_double Mandate.new, birth_year: 1960 }
  let(:profile_repo) { object_double ProfileData::ForMandateRepository.new, all: profile_data }
  let(:profile_data) { [] }

  before do
    allow(ProfileData::ForMandateRepository).to receive(:new).and_return profile_repo
  end

  it "uses repository to retrieve profile data" do
    expect(profile_repo).to receive(:all).with(mandate, property_identifier: kind_of(Array))
    situation.occupation
  end

  describe "#occupation" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_brf_378369",
          value: "ENGINEER"
        )
      ]
    end

    it "returns occupation" do
      expect(situation.occupation).to eq "ENGINEER"
    end
  end

  describe "#occupation_description" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_jbdscrptn_7a1fe6",
          value: "und Mitglied einer berufsstandischen Kammer"
        )
      ]
    end
    let(:expected_result) do
      "und Mitglied einer berufsstandischen Kammer"
    end

    it "returns occupation description" do
      expect(situation.occupation_description).to eq expected_result
    end
  end

  describe "#occupation_details" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_jbdtls_da14db",
          value: "und nicht gesetzlich rentenversichert"
        )
      ]
    end
    let(:expected_result) do
      "und nicht gesetzlich rentenversichert"
    end

    it "returns occupation details" do
      expect(situation.occupation_details).to eq expected_result
    end
  end

  describe "#yearly_gross_income" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_brttnkmmn_bad238",
          value: "100000"
        )
      ]
    end

    it "returns gross income" do
      expect(situation.yearly_gross_income).to eq 100_000
    end
  end

  describe "#yearly_gross_income_cents" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_brttnkmmn_bad238",
          value: "100000"
        )
      ]
    end

    it "returns gross income" do
      expect(situation.yearly_gross_income_cents).to eq 10_000_000
    end
  end

  describe "#has_kids?" do
    let(:profile_data) do
      [
        object_double(
          ProfileDatum.new,
          property_identifier: "text_kndr_9a9236",
          value: value
        )
      ]
    end

    context "with 'Ja' response" do
      let(:value) { "Ja" }

      it "returns true" do
        expect(situation.has_kids?).to eq true
      end
    end

    context "with 'Nein' response" do
      let(:value) { "Nein" }

      it "returns false" do
        expect(situation.has_kids?).to eq false
      end
    end

    context "with '0' response" do
      let(:value) { "0" }

      it "returns false" do
        expect(situation.has_kids?).to eq false
      end
    end

    context "with '1' response" do
      let(:value) { "1" }

      it "returns true" do
        expect(situation.has_kids?).to eq true
      end
    end
  end

  describe "#church_member?" do
    it "returns hardcoded value" do
      expect(situation).not_to be_church_member
    end
  end

  describe "#retirement_age" do
    let(:retirement_age) { ->(_) { 65 } }

    before { allow(Domain::Retirement::LegalRetirementAge).to receive(:new).and_return retirement_age }

    it "returns retirement age of mandate" do
      expect(situation.retirement_age).to eq 65
    end
  end
end

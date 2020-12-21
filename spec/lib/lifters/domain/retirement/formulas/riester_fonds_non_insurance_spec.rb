# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Formulas::RiesterFondsNonInsurance do
  describe ".guaranteed" do
    let(:guaranteed) { 150_000 }
    let(:years_till_retirement) { 36 }
    let(:premium) { 161_340 }

    context "when man" do
      let(:remaining_life_years) { 20 }
      let(:gender) { "male" }

      it "uses 0.62 on calculation" do
        expect(described_class.guaranteed(guaranteed,
                                          premium,
                                          remaining_life_years,
                                          years_till_retirement,
                                          gender)).to be_within(0.00001).of(5737.459608345068)
      end
    end

    context "when female" do
      let(:remaining_life_years) { 23 }
      let(:gender) { "female" }

      it "uses 0.72 on calculation" do
        expect(described_class.guaranteed(guaranteed,
                                          premium,
                                          remaining_life_years,
                                          years_till_retirement,
                                          gender)).to be_within(0.00001).of(7617.889402672397)
      end
    end
  end

  describe ".surplus" do
    let(:guaranteed) { 150_000 }
    let(:yearly_premium) { 1613.40 }
    let(:years_till_retirement) { 35 }

    context "male" do
      let(:gender) { "male" }
      let(:remaining_life_years) { 20 }

      it "uses 0.62 on calculation" do
        expect(described_class.surplus(guaranteed,
                                       yearly_premium,
                                       years_till_retirement,
                                       remaining_life_years,
                                       gender)).to be_within(0.00001).of(1473.031942521505)
      end
    end

    context "female" do
      let(:gender) { "female" }
      let(:remaining_life_years) { 23 }

      it "uses 0.72 on calculation" do
        expect(described_class.surplus(guaranteed,
                                       yearly_premium,
                                       years_till_retirement,
                                       remaining_life_years,
                                       gender)).to be_within(0.00001).of(1509.0591001141258)
      end
    end
  end
end

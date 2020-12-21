# frozen_string_literal: true

# == Schema Information
#
# Table name: miles_more_booking_tables
#
#  id         :integer          not null, primary key
#  valid_from :date
#  rules      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "rails_helper"

RSpec.describe MilesMoreBookingTable, type: :model do
  # Setup
  let!(:base_date) { Time.zone.today }
  let!(:table1) { create(:miles_more_booking_table, :with_rules_count_first_product, valid_from: base_date - 1) }
  let!(:table2) { create(:miles_more_booking_table, :with_rules_extra_1000, valid_from: base_date) }
  let!(:table3) { create(:miles_more_booking_table, :with_rules_normal, valid_from: base_date + 2) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations
  describe "ident" do
    it { is_expected.to validate_uniqueness_of(:ident) }
  end
  # Callbacks
  # Instance Methods

  # Class Methods
  describe ".rules_for_date" do
    it "should find the correct booking table" do
      rules = described_class.rules_for_date(base_date)
      expect(rules).to be_truthy
      expect(rules["2"]["base"]).to be(2000)
    end

    it "should find the earliest table whose valid_from is smaller than the passed in date" do
      rules = described_class.rules_for_date(base_date + 1)
      expect(rules).to eq(table2.rules)
    end

    it "should find the latest when given a date in the future" do
      rules = described_class.rules_for_date(base_date + 3)
      expect(rules).to eq(table3.rules)
    end

    it "should find the latest when given a date in the future" do
      rules = described_class.rules_for_date(base_date + 3)
      expect(rules).to eq(table3.rules)
    end

    it "should return a booking table with 0 miles when date is past first valid_from of a table" do
      rules = described_class.rules_for_date(base_date - 2)
      expect(rules["2"]["base"]).to be(0)
    end
  end

  describe ".rules_for_ident" do
    let(:ident) { "rulemamcreditcardtwo" }

    before do
      table1.ident = ident
      table1.save!
    end

    context "when a rule with the ident exists" do
      it "returns the correct rule" do
        rule = described_class.rules_for_ident(ident)
        expect(rule).to eq(table1.rules)
      end
    end

    context "when the ident is nil" do
      it "returns the default rule" do
        rule = described_class.rules_for_ident(nil)
        expect(rule).to eq(MilesMoreBookingTable.default_result)
      end
    end

    context "when the rules with ident dont exists in the database" do
      it "returns the default rule" do
        rule = described_class.rules_for_ident("fakeident")
        expect(rule).to eq(MilesMoreBookingTable.default_result)
      end
    end
  end
end

# frozen_string_literal: true
# == Schema Information
#
# Table name: insurance_comparisons
#
#  id                       :integer          not null, primary key
#  uuid                     :string
#  mandate_id               :integer
#  category_id              :integer
#  created_at               :datetime
#  updated_at               :datetime
#  expected_insurance_begin :datetime
#  opportunity_id           :integer
#  meta                     :jsonb
#


require "rails_helper"

RSpec.describe InsuranceComparison::DisabilityComparison do
  let(:positive_integer) { 1 + (rand * 100).round }

  context "age" do
    it "sets the age as meta" do
      subject.age = positive_integer
      expect(subject.meta["age"]).to eq(positive_integer)
    end

    it "reads the age as meta" do
      subject.meta["age"] = positive_integer
      expect(subject.age).to eq(positive_integer)
    end
  end

  context "pension" do
    it "sets the pension as meta" do
      subject.pension = positive_integer
      expect(subject.meta["pension"]).to eq(positive_integer)
    end

    it "reads the pension as meta" do
      subject.meta["pension"] = positive_integer
      expect(subject.pension).to eq(positive_integer)
    end
  end

  context "age scope" do
    it "returns an empty collection, if nothing is found" do
      expect(described_class.by_age(positive_integer)).to be_empty
    end

    it "will find one, if one matches" do
      comparison = create(:disability_comparison, age: positive_integer)
      expect(described_class.by_age(positive_integer).first).to eq(comparison)
    end

    it "will find none, if not matching" do
      create(:disability_comparison, age: positive_integer + 1)
      expect(described_class.by_age(positive_integer)).to be_empty
    end

    it "will find all matching" do
      comparison1 = create(:disability_comparison, age: positive_integer)
      comparison2 = create(:disability_comparison, age: positive_integer)
      create(:disability_comparison, age: positive_integer + 1)
      expect(described_class.by_age(positive_integer)).to eq([comparison1, comparison2])
    end
  end

  context "pension scope" do
    it "returns an empty collection, if nothing is found" do
      expect(described_class.by_pension(positive_integer)).to be_empty
    end

    it "will find one, if one matches" do
      comparison = create(:disability_comparison, pension: positive_integer)
      expect(described_class.by_pension(positive_integer).first).to eq(comparison)
    end

    it "will find none, if not matching" do
      create(:disability_comparison, pension: positive_integer + 1)
      expect(described_class.by_pension(positive_integer)).to be_empty
    end

    it "will find all matching" do
      comparison1 = create(:disability_comparison, pension: positive_integer)
      comparison2 = create(:disability_comparison, pension: positive_integer)
      create(:disability_comparison, pension: positive_integer + 1)
      expect(described_class.by_pension(positive_integer)).to eq([comparison1, comparison2])
    end
  end
end

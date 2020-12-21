# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileData::ForMandateRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate)   { create :mandate }
  let(:property1) { create :profile_property, identifier: "SALARY" }
  let(:property2) { create :profile_property, identifier: "OCCUPATION" }

  let!(:profile_data1) do
    create :profile_datum, mandate: mandate, property: property1, created_at: 5.minutes.ago
  end
  let!(:profile_data2) do
    create :profile_datum, mandate: mandate, property: property2, created_at: 5.minutes.ago
  end

  describe "#all" do
    it "returns AR relation of profile data" do
      data = repo.all(mandate)
      expect(data).to be_kind_of ActiveRecord::Relation
      expect(data).to match_array [profile_data1, profile_data2]
    end

    context "when mandate has multiple profile data records of the same property" do
      let!(:profile_data3) do
        create :profile_datum, mandate: mandate, property: property2, created_at: 1.minute.ago
      end

      it "returns the latest one only" do
        expect(repo.all(mandate)).to match_array [profile_data1, profile_data3]
      end
    end
  end
end

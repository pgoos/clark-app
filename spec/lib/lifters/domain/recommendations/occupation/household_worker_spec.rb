# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::Occupation::HouseholdWorker do
  describe ".call" do
    context "when above 50 years old" do
      let(:expected_idents) do
        %w[03b12732 5bfa54ce cf064be0 2fc69451]
      end
      let(:age) { 51 }

      it "returns placeholder categories' idents" do
        expect(described_class.call(age)).to match_array expected_idents
      end
    end

    context "when under 50 years old" do
      let(:expected_idents) do
        %w[03b12732 5bfa54ce cf064be0 2fc69451 7619902c]
      end
      let(:age) { 49 }

      it "includes care insurance" do
        expect(described_class.call(age)).to match_array expected_idents
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::Occupation::IndependentlyInsured do
  describe ".call" do
    context "when above 50 years old" do
      let(:age) { 51 }
      let(:expected_idents) do
        %w[03b12732 377e1f7c 5bfa54ce cf064be0 14418a53]
      end

      it "returns placeholder categories' idents" do
        expect(described_class.call(age)).to match_array expected_idents
      end
    end

    context "when under 50 years old" do
      let(:age) { 49 }
      let(:expected_idents) do
        %w[03b12732 377e1f7c 5bfa54ce cf064be0 dienstunfaehigkeit]
      end

      it "includes dienstunfaehigkeit" do
        expect(described_class.call(age)).to match_array expected_idents
      end
    end
  end
end

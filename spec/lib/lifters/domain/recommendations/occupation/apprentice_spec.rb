# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::Occupation::Apprentice do
  describe ".call" do
    let(:expected_idents) do
      %w[3d439696 2fc69451 03b12732 5bfa54ce cf064be0 377e1f7c]
    end

    it "returns placeholder categories' idents" do
      expect(described_class.call(nil)).to match_array expected_idents
    end
  end
end

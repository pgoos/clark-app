# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaybackMailerHelper, type: :helper do
  let(:key) { "unlocked_points_amount" }
  let(:paragraph) { "Test sentence [[#{key}]] end" }

  describe "#payback_interpolate_paragraph" do
    context "value is provided is provided" do
      it "includes it in the string" do
        value = 100

        result = payback_interpolate_paragraph(paragraph, key, value)
        expect(result).to eq("Test sentence 100 end")
      end
    end

    context "value is nil" do
      it "excludes variable from the string" do
        result = payback_interpolate_paragraph(paragraph, key, nil)
        expect(result).to eq("Test sentence  end")
      end
    end

    context "value is nil and default" do
      it "includes default value in the string" do
        result = payback_interpolate_paragraph(paragraph, key, nil, 0)
        expect(result).to eq("Test sentence 0 end")
      end
    end
  end
end

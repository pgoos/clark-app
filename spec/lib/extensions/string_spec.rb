# frozen_string_literal: true

require "rails_helper"

RSpec.describe String do
  describe ".formatted_number?" do
    it "returns true for 1.500,00 formatted number string" do
      expect("1.500,00".formatted_number?).to be_truthy
    end

    it "returns true for 1.500 formatted number string" do
      expect("1.500".formatted_number?).to be_truthy
    end

    it "returns true for 1500 formatted number string" do
      expect("1500".formatted_number?).to be_truthy
    end

    it "returns true for 0 formatted number string" do
      expect("0".formatted_number?).to be_truthy
    end

    it "returns true for -1.500,00 formatted number string" do
      expect("-1.500,00".formatted_number?).to be_truthy
    end

    it "returns true for 1,234,123 formatted number string" do
      expect("1,234,123".formatted_number?).to be_truthy
    end

    it "returns false for 123a formatted number string" do
      expect("123a".formatted_number?).to be_falsy
    end

    it "returns false for 123.00a formatted number string" do
      expect("123a".formatted_number?).to be_falsy
    end
  end

  describe ".positive_formatted_number?" do
    it "returns true for 1.500,00 formatted number string" do
      expect("1.500,00".positive_formatted_number?).to be_truthy
    end

    it "returns true for 123 formatted number string" do
      expect("123".positive_formatted_number?).to be_truthy
    end

    it "returns false for -1.500,00 formatted number string" do
      expect("-1.500,00".positive_formatted_number?).to be_falsy
    end

    it "returns false for -123 formatted number string" do
      expect("-123".positive_formatted_number?).to be_falsy
    end

    it "returns false for 0 formatted number string" do
      expect("0".positive_formatted_number?).to be_falsy
    end

    it "returns false for 123abcde formatted number string" do
      expect("123abcde".positive_formatted_number?).to be_falsy
    end
  end

  describe ".negative_formatted_number?" do
    it "returns true for -1.500,00 formatted number string" do
      expect("-1.500,00".negative_formatted_number?).to be_truthy
    end

    it "returns true for -123 formatted number string" do
      expect("-123".negative_formatted_number?).to be_truthy
    end

    it "returns false for 0 formatted number string" do
      expect("0".negative_formatted_number?).to be_falsy
    end

    it "returns false for 1.500,00 formatted number string" do
      expect("1.500,00".negative_formatted_number?).to be_falsy
    end

    it "returns false for 123 formatted number string" do
      expect("123".negative_formatted_number?).to be_falsy
    end
  end
end

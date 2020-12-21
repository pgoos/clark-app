# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValueTypes::Date do
  subject { ValueTypes::Date.new(date) }

  describe ".to_s" do
    it "uses the format in to_s" do
      expect(ValueTypes::Date.new("2018-02-01").to_s).to eq("01.02.2018")
    end
  end

  describe "#to_date" do
    context "when german format" do
      let(:date) { "15.1.2019" }

      it "returns a valid Date object based on %d.%m.%Y" do
        expect(subject.to_date).to eq(Date.new(2019, 1, 15))
      end

      context "with 2 digits on year" do
        subject { ValueTypes::Date.new(date, format) }

        let(:date)   { "15.1.19" }
        let(:format) { "%d.%m.%y" }

        it "returns a valid Date object based on %d.%m.%y" do
          expect(subject.to_date).to eq(Date.new(2019, 1, 15))
        end
      end
    end

    context "when ISO 8601 (american format)" do
      let(:date) { "2019.01.15" }

      it "returns a valid Date object based on %Y.%m.%d" do
        expect(subject.to_date).to eq(Date.new(2019, 1, 15))
      end
    end

    context "when format not supported" do
      let(:date) { "0000.00.00" }

      it "raises ArgumentError exception" do
        expect { subject.to_date }.to raise_error("'#{date}' cannot be parsed to a date!")
      end
    end
  end
end

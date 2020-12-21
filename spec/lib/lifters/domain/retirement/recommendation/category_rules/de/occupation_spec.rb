# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Recommendation::CategoryRules::De::Occupation do
  subject { described_class.new(situation) }

  describe "#call" do
    let(:state_ident)     { "84a5fba0" }
    let(:private_ident)   { "vorsorgeprivat" }
    let(:corporate_ident) { "1ded8a0f" }
    let(:situation) do
      instance_double Domain::Situations::RetirementSituation,
                      occupation: occupation
    end

    before do
      allow(Domain::Situations::RetirementSituation).to receive(:new) { situation }

      @statutory_category = create(:category, ident: state_ident)
      @private_category = create(:category, ident: private_ident)
      @corporate_category = create(:category, ident: corporate_ident)
    end

    context "when occupation not on private/corporate scope" do
      let(:occupation) { "Schuler" }
      let(:expected_idents) do
        [state_ident, private_ident, corporate_ident]
      end

      it "returns statutory category" do
        subject.idents.each do |ident|
          expect(expected_idents).to include ident
        end
      end
    end

    context "when occupation doesnt support corporate" do
      let(:occupation) { "Freiberufler" }
      let(:expected_idents) do
        [state_ident, private_ident]
      end

      it "returns only private and statutory categories" do
        subject.idents.each do |ident|
          expect(expected_idents).to include ident
        end
      end
    end

    context "when occupation doesn't support state and corporate" do
      let(:occupation) { "Freie Heilfursorge" }
      let(:expected_idents) { [private_ident] }

      it "returns an empty array" do
        expect(subject.idents).to eq expected_idents
      end
    end

    context "when occupation has no restrictions" do
      let(:occupation) { "Angestellter" }
      let(:expected_idents) do
        [state_ident, private_ident, corporate_ident]
      end

      it "returns private, statutory, and corporate categories" do
        subject.idents.each do |ident|
          expect(expected_idents).to include ident
        end
      end
    end
  end
end

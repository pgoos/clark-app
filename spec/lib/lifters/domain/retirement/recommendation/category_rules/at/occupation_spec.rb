# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Recommendation::CategoryRules::At::Occupation do
  subject { described_class.new(situation) }

  describe "#call" do
    let(:private_ident) { "vorsorgeprivat" }
    let(:situation) do
      instance_double Domain::Situations::RetirementSituation,
                      occupation: occupation
    end

    before do
      allow(Domain::Situations::RetirementSituation).to receive(:new) { situation }

      @private_category = create(:category, ident: private_ident)
    end

    context "when occupation on private scope" do
      let(:occupation) { "Angestellter" }
      let(:expected_idents) do
        [private_ident]
      end

      it "returns statutory category" do
        subject.idents.each do |ident|
          expect(expected_idents).to include ident
        end
      end
    end

    context "when occupation doesnt support private" do
      let(:occupation) { "Schuler" }
      let(:expected_idents) do
        [state_ident, private_ident]
      end

      it "returns only private and statutory categories" do
        expect(subject.idents).to eq nil
      end
    end
  end
end

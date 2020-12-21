# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Recommendations::Builder do
  describe ".call" do
    let(:mandate)   { create(:mandate) }
    let(:situation) { instance_double(Domain::Situations::RetirementSituation, occupation: occupation) }

    before do
      expected_idents.each do |ident|
        create(:category, ident: ident)
      end

      allow(Domain::Situations::RetirementSituation).to receive(:new).with(mandate) { situation }
    end

    context "when occupation is ::JobSeeker" do
      let(:occupation) { "Arbeitssuchend" }
      let(:expected_idents) do
        %w[2fc69451 03b12732]
      end

      before { allow(Domain::Recommendations::Occupation::JobSeeker).to receive(:call) { expected_idents } }

      it "creates categories based on job seeker idents" do
        described_class.call(mandate)
        expect(mandate.recommendations.map(&:category).map(&:ident)).to match_array expected_idents
      end
    end

    context "when occupation is ::HouseholdWorker" do
      let(:occupation) { "Hausfrauen/-manner" }
      let(:expected_idents) do
        %w[03b12732 5bfa54ce cf064be0 7619902c]
      end

      before { allow(Domain::Recommendations::Occupation::HouseholdWorker).to receive(:call) { expected_idents } }

      it "creates categories based on house worker idents" do
        described_class.call(mandate)
        expect(mandate.recommendations.map(&:category).map(&:ident)).to match_array expected_idents
      end
    end

    context "when occupation is ::IndependentlyInsured" do
      let(:occupation) { "Freie Heilfursorge" }
      let(:expected_idents) do
        %w[03b12732 377e1f7c 5bfa54ce cf064be0 dienstunfaehigkeit]
      end

      before { allow(Domain::Recommendations::Occupation::IndependentlyInsured).to receive(:call) { expected_idents } }

      it "creates categories based on independently insured idents" do
        described_class.call(mandate)
        expect(mandate.recommendations.map(&:category).map(&:ident)).to match_array expected_idents
      end
    end

    context "when occupation is ::Apprentice" do
      let(:occupation) { "Auszubildender" }
      let(:expected_idents) do
        %w[3d439696 2fc69451 03b12732 5bfa54ce cf064be0 377e1f7c]
      end

      before { allow(Domain::Recommendations::Occupation::Apprentice).to receive(:call) { expected_idents } }

      it "creates categories based on apprentice idents" do
        described_class.call(mandate)
        expect(mandate.recommendations.map(&:category).map(&:ident)).to match_array expected_idents
      end
    end

    context "when occupation not supported" do
      let(:occupation) { "Not supported" }
      let(:expected_idents) { [] }

      it "doesn't create any recommendation" do
        described_class.call(mandate)
        expect(mandate.recommendations).to be_empty
      end
    end

    context "when recommendation already exists" do
      let(:occupation) { "Auszubildender" }
      let(:expected_idents) { %w[3d439696] }

      before do
        allow(Domain::Recommendations::Occupation::Apprentice).to receive(:call) { expected_idents }
        category = Category.find_by(ident: "3d439696")
        create(:recommendation, mandate: mandate, category: category)
      end

      it "doesn't try to create it again" do
        expect { described_class.call(mandate) }.not_to raise_error
      end
    end
  end
end

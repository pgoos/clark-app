# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Recommendation::CategoryRulesLoader do
  subject { described_class.new(situation) }

  let(:situation) do
    instance_double Domain::Situations::RetirementSituation,
                    occupation: "Angestellter"
  end

  describe "#call" do
    context "when AT locale" do
      let(:occupation_rule) do
        instance_double Domain::Retirement::Recommendation::CategoryRules::At::Occupation
      end
      let(:occupation_idents) { ["vorsorgeprivat"] }

      before do
        allow(Internationalization).to receive(:locale).and_return(:at)
        allow(occupation_rule).to receive(:idents).and_return occupation_idents
      end

      it "loads classes responsible for selecting idents" do
        expect(Domain::Retirement::Recommendation::CategoryRules::At::Occupation)
          .to receive(:new).with(situation).and_return occupation_rule
        subject.call
      end

      it "returns idents from all category rules" do
        expect(subject.call).to eq ["vorsorgeprivat"]
      end
    end

    context "when DE locale" do
      let(:occupation_rule) do
        instance_double Domain::Retirement::Recommendation::CategoryRules::De::Occupation
      end
      let(:occupation_idents) { %w[vorsorgeprivat 1ded8a0f 84a5fba0] }

      before do
        allow(Internationalization).to receive(:locale).and_return(:de)
        allow(occupation_rule).to receive(:idents).and_return occupation_idents
      end

      it "loads classes responsible for selecting idents" do
        expect(Domain::Retirement::Recommendation::CategoryRules::De::Occupation)
          .to receive(:new).with(situation).and_return occupation_rule
        subject.call
      end

      it "returns idents from all category rules" do
        expect(subject.call).to eq %w[vorsorgeprivat 1ded8a0f 84a5fba0]
      end
    end
  end
end

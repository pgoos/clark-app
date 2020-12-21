# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Eligible do
  subject(:eligible) { described_class.new mandate, situation }

  let(:mandate) { build_stubbed :mandate, :created }
  let(:situation) do
    double :situation, occupation: "Abteilungsleiter",
                       occupation_description: "",
                       occupation_details: "",
                       yearly_gross_income?: true
  end

  describe "#maybe_eligible?" do
    it { expect(eligible.eligible?).to eq true }

    context "when mandate is revoked" do
      let(:mandate) { build_stubbed :mandate, :revoked }

      it { expect(eligible.maybe_eligible?).to eq false }
    end

    context "when already retired" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: 67.years.ago + 1.day }

      it { expect(eligible.maybe_eligible?).to eq false }
    end

    context "when occupation is out of scope" do
      before { allow(situation).to receive(:occupation).and_return "Schuler" }

      it { expect(eligible.maybe_eligible?).to eq false }
    end

    context "when salary is empty" do
      before { allow(situation).to receive(:yearly_gross_income?).and_return false }

      it { expect(eligible.maybe_eligible?).to eq true }
    end

    context "when mandate's birthdate is not set" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: nil }

      it { expect(eligible.maybe_eligible?).to eq true }
    end
  end

  describe "#eligible?" do
    it { expect(eligible.eligible?).to eq true }

    context "when mandate is not completed" do
      let(:mandate) { build_stubbed :mandate, :in_creation }

      it { expect(eligible.eligible?).to eq false }
    end

    context "when already retired" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: 67.years.ago + 1.day }

      it { expect(eligible.eligible?).to eq false }
    end

    context "occupation" do
      context "DE" do
        before { allow(Internationalization).to receive(:locale).and_return :de }

        it "calls the proper service to check occupation policy" do
          expect_any_instance_of(Domain::Retirement::EligibilityPolicies::De::OccupationPolicy)
            .to receive(:eligible?)
          eligible.eligible?
        end
      end

      context "AT" do
        before { allow(Internationalization).to receive(:locale).and_return :at }

        it "calls the proper service to check occupation policy" do
          expect_any_instance_of(Domain::Retirement::EligibilityPolicies::At::OccupationPolicy)
            .to receive(:eligible?)
          eligible.eligible?
        end
      end
    end

    context "when salary is empty" do
      before { allow(situation).to receive(:yearly_gross_income?).and_return false }

      it { expect(eligible.eligible?).to eq false }
    end

    context "when mandate's birthdate is not set" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: nil }

      it { expect(eligible.eligible?).to eq false }
    end
  end

  describe "#state" do
    it { expect(eligible.state).to eq "ACCEPTED" }

    context "when mandate is not completed" do
      let(:mandate) { build_stubbed :mandate, :in_creation }

      it { expect(eligible.state).to eq "MANDATE_NOT_SIGNED" }
    end

    context "when already retired" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: 67.years.ago + 1.day }

      it { expect(eligible.state).to eq "TOO_OLD" }
    end

    context "when occupation is out of scope" do
      before do
        allow_any_instance_of(described_class).to receive(:eligible?).and_return false
        allow_any_instance_of(Domain::Retirement::EligibilityPolicies::OccupationPolicy)
          .to receive(:out_of_scope?)
          .and_return true
      end

      it { expect(eligible.state).to eq "OCCUPATION_OUT_OF_SCOPE" }
    end

    context "with salary but without occupation" do
      before { allow(situation).to receive(:occupation).and_return nil }

      it { expect(eligible.state).to eq "RETIREMENTCHECK_NOT_DONE" }
    end

    context "when mandate's birthdate is not set" do
      let(:mandate) { build_stubbed :mandate, :created, birthdate: nil }

      before { allow(situation).to receive(:occupation).and_return nil }

      it { expect(eligible.state).to eq "RETIREMENTCHECK_NOT_DONE" }
    end

    context "when salary is empty" do
      before { allow(situation).to receive(:yearly_gross_income?).and_return false }

      it { expect(eligible.state).to eq "RETIREMENTCHECK_NOT_DONE" }
    end
  end
end

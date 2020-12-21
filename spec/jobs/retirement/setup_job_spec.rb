# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::SetupJob, type: :job do
  it { is_expected.to be_a(ClarkJob) }

  describe ".perform" do
    let(:mandate)   { create(:mandate) }
    let(:eligible)  { instance_double(Domain::Retirement::Eligible) }

    before do
      allow(Domain::Retirement::Eligible).to receive(:new).with(mandate) { eligible }

      create(:plan, ident: "brdb0998")
      create(:category, ident: "84a5fba0")
    end

    context "when mandate eligible for retirement" do
      before do
        allow(eligible).to receive(:eligible?).and_return(true)

        subject.perform(mandate.id)
      end

      it { expect(eligible).to have_received(:eligible?) }

      it "creates a state pension product" do
        state_pension = mandate.retirement_products.state
        expect(state_pension).not_to be_empty
      end
    end

    context "when mandate not eligible for retirement" do
      before do
        allow(eligible).to receive(:eligible?).and_return(false)

        subject.perform(mandate.id)
      end

      it { expect(eligible).to have_received(:eligible?) }

      it "doesnt create state pension product" do
        state_pension = mandate.retirement_products.state
        expect(state_pension).to be_empty
      end
    end
  end
end

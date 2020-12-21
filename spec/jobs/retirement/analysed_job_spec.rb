# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::AnalysedJob, type: :job do
  it { is_expected.to be_a(ClarkJob) }

  describe ".perform" do
    let(:old_state) { "created" }
    let(:retirement_product) { create(:retirement_product) }

    before do
      allow(Retirement::Product).to receive(:find).with(retirement_product.id) { retirement_product }
      allow(Domain::Mandates::Notifications::Retirement).to receive(:call).with(retirement_product)

      subject.perform(retirement_product.id, old_state, current_state)
    end

    context "when old_state is equal current_state" do
      let(:current_state) { "created" }

      it "doesn't trigger #publish_analysed_event" do
        expect(Domain::Mandates::Notifications::Retirement).not_to have_received(:call)
      end
    end

    context "when old_state is differnt from current_state" do
      let(:current_state) { "details_available" }

      it "triggers Retirement::Product#publish_analysed_event" do
        expect(Domain::Mandates::Notifications::Retirement).to have_received(:call)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::Messenger::OnboardJob, type: :job do
  it { is_expected.to be_a(ClarkJob) }

  describe ".perform" do
    let(:mandate)       { create(:mandate) }
    let(:template_name) { "group1" }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:retirement_onboard).with(mandate, template_name)

      subject.perform(mandate.id, template_name)
    end

    it { expect(OutboundChannels::Messenger::TransactionalMessenger).to have_received(:retirement_onboard) }
  end
end

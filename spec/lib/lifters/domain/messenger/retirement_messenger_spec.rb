# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::RetirementMessenger do
  describe ".onboard" do
    let(:mandate) { create(:mandate) }
    let(:options) { {name: mandate&.first_name} }
    let(:sender)  { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      allow(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.retirement_onboard(mandate, template_name)
    end

    context "with valid mandate and template" do
      let(:template_name) { "retirement_onboarding_group1" }

      it { expect(sender).to have_received(:send_message) }
    end

    context "with invalid mandate" do
      let(:mandate)       { nil }
      let(:template_name) { "example_template" }

      it { expect(sender).not_to have_received(:send_message) }
    end

    context "with invalid template" do
      let(:template_name) { "" }

      it { expect(sender).not_to have_received(:send_message) }
    end
  end

  describe ".analysed" do
    let(:mandate)  { create(:mandate) }
    let(:category) { create(:category) }
    let(:options)  { {name: mandate&.first_name, category: category.name} }
    let(:sender)   { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      allow(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.analysed(mandate, template_name, category)
    end

    context "with valid mandate and template" do
      let(:template_name) { "retirement_product_analysed" }

      it { expect(sender).to have_received(:send_message) }
    end

    context "with invalid mandate" do
      let(:mandate)       { nil }
      let(:template_name) { "example_template" }

      it { expect(sender).not_to have_received(:send_message) }
    end

    context "with invalid template" do
      let(:template_name) { "" }

      it { expect(sender).not_to have_received(:send_message) }
    end
  end
end

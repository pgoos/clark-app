# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::WelcomeCustomerMessenger do
  describe ".self_service_customer_created" do
    let(:mandate) { double(:mandate) }
    let(:sender)  { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }
    let(:options) { { created_by_robo: false } }
    let(:template_name) { :self_service_customer_created }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      allow(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.self_service_customer_created(mandate)
    end

    it { expect(sender).to have_received(:send_message) }
  end

  describe ".customer_signed_mandate" do
    let(:customer_name) { Faker::Name.first_name }
    let(:mandate) { double(:mandate, first_name: customer_name) }
    let(:sender)  { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }
    let(:options) { { created_by_robo: false, customer_name: customer_name } }
    let(:template_name) { :customer_signed_mandate }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      allow(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.customer_signed_mandate(mandate)
    end

    it { expect(sender).to have_received(:send_message) }
  end

  describe ".voucher_customer_signed_mandate" do
    let(:customer_name) { Faker::Name.first_name }
    let(:mandate) { double(:mandate, first_name: customer_name) }
    let(:sender)  { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }
    let(:options) { { created_by_robo: false, customer_name: customer_name } }
    let(:template_name) { :voucher_customer_signed_mandate }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      allow(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.voucher_customer_signed_mandate(mandate)
    end

    it { expect(sender).to have_received(:send_message) }
  end
end

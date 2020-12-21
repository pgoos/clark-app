# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::ContractCancellationMessenger do
  let(:mandate) { double(:mandate, first_name: "John") }
  let(:product) { double(:product, id: 1, mandate: mandate, category_name: "pkv", company_name: "Fancy Company") }
  let(:sender)  { instance_double(OutboundChannels::Messenger::TransactionalMessenger) }

  shared_examples "a contract cancellation message behaviour" do
    it do
      expect(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:new).with(mandate, template_name, options, kind_of(Config::Options)) { sender }
      expect(sender).to receive(:send_message)

      OutboundChannels::Messenger::TransactionalMessenger.public_send(template_name, product)
    end
  end

  describe "#notify_contract_cancellation" do
    let(:options) { { created_by_robo: false, product_id: product.id, name: mandate.first_name, category_name: "pkv" } }
    let(:template_name) { :notify_contract_cancellation }

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#notify_contract_cancellation_general_sold_by_others_known_end_date" do
    let(:template_name) { :notify_contract_cancellation_general_sold_by_others_known_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#notify_contract_cancellation_general_sold_by_others_unknown_end_date" do
    let(:template_name) { :notify_contract_cancellation_general_sold_by_others_unknown_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#notify_contract_cancellation_general_sold_by_us_known_end_date" do
    let(:template_name) { :notify_contract_cancellation_general_sold_by_us_known_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#notify_contract_cancellation_general_sold_by_us_unknown_end_date" do
    let(:template_name) { :notify_contract_cancellation_general_sold_by_us_unknown_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#kfz_contract_cancellation_best_direct_insurer_known_end_date" do
    let(:template_name) { :kfz_contract_cancellation_best_direct_insurer_known_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end

  describe "#kfz_contract_cancellation_best_direct_insurer_unknown_end_date" do
    let(:template_name) { :kfz_contract_cancellation_best_direct_insurer_unknown_end_date }
    let(:options) do
      {
        created_by_robo: false,
        product_id: product.id,
        first_name: mandate.first_name,
        company: product.company_name,
        category: product.category_name
      }
    end

    it_behaves_like "a contract cancellation message behaviour"
  end
end

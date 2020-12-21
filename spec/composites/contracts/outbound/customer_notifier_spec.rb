# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/outbound/customer_notifier"

RSpec.describe Contracts::Outbound::CustomerNotifier, :integration do
  let(:contract) { double(customer_id: 1, category_name: "Some category") }
  let(:additional_information) { "Some information" }
  let(:possible_reasons) { %i[reason_1 reason_2] }

  describe "#request_correction" do
    before do
      allow(ContractMailer).to receive(:request_correction).and_return(double(deliver_later: true))
    end

    it "sends an email" do
      expect(contract).to receive(:customer_id)
      expect(contract).to receive(:category_name)
      expect(ContractMailer)
        .to receive(:request_correction).with(1, "Some category", possible_reasons, additional_information)

      described_class.request_correction(contract, possible_reasons, additional_information)
    end
  end
end

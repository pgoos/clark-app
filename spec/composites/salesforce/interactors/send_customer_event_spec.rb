# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/send_customer_event"

RSpec.describe Salesforce::Interactors::SendCustomerEvent, :integration do
  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }

  context "Mandate accept" do
    let!(:mandate_accept_business_event) { create(:business_event, entity: mandate, action: "accept") }

    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(mandate_accept_business_event.id, "Mandate", "accept")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Mandate", "accept")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(mandate_accept_business_event.id, "Mandate", "accept")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end

  context "Appointment create" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :requested) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "create") }

    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(appointment_created_business_event.id, "Appointment", "create")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Appointment", "create")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(appointment_created_business_event.id, "Appointment", "create")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end

  context "Appointment accept" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :accepted) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "accept") }

    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(appointment_created_business_event.id, "Appointment", "accept")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Appointment", "accept")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(appointment_created_business_event.id, "Appointment", "accept")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end

  context "Appointment cancel" do
    let!(:appointment) { create(:appointment, mandate: mandate, state: :cancelled) }
    let!(:appointment_created_business_event) { create(:business_event, entity: appointment, action: "cancel") }

    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(appointment_created_business_event.id, "Appointment", "cancel")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Appointment", "cancel")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(appointment_created_business_event.id, "Appointment", "cancel")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end

  context "Mandate Demand check completed" do
    it "is successful" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(mandate.id, "Mandate", "demand-check-completed")
      expect(result).to be_successful
    end

    it "is success with nil" do
      object = described_class.new
      allow(object).to receive(:send_event).and_return(OpenStruct.new(status: 201))
      result = object.call(10_000, "Mandate", "demand-check-completed")
      expect(result).to be_successful
    end

    it "is error" do
      object = described_class.new
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(status: 401))
      expect {
        object.call(mandate.id, "Mandate", "demand-check-completed")
      }.to raise_error(Salesforce::Outbound::Errors::BadRequestError)
    end
  end
end

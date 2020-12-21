# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service do
  let!(:define_service) do
    allow(Settings).to(
      receive_message_chain("retirement.calculation.service")
        .and_return(service_name)
    )
  end

  describe ".service_class" do
    context "when service name is defined" do
      context "when service name is correct" do
        let(:service_name) { "varias" }

        it "returns a module" do
          expect(subject.service_class).to(
            eq(Domain::Retirement::Service::Varias)
          )
        end
      end

      context "when service name is wrong" do
        let(:service_name) { "wrong_service_name" }

        it "raises an exception" do
          expect { subject.service_class }.to(
            raise_error(
              NameError,
              "uninitialized constant Domain::Retirement::Service::WrongServiceName"
            )
          )
        end
      end
    end
  end

  describe ".enabled?" do
    context "when service name is defined" do
      let(:service_name) { "varias" }

      it "returns true" do
        expect(subject).to be_enabled
      end
    end

    context "when service name is nil" do
      let(:service_name) { nil }

      it "returns false" do
        expect(subject).not_to be_enabled
      end
    end

    context "when service name is empty" do
      let(:service_name) { "" }

      it "returns false" do
        expect(subject).not_to be_enabled
      end
    end
  end

  describe ".call" do
    let(:questionnaire_response) { create :questionnaire_response }

    let!(:service_class) do
      concrete_service = double

      allow(concrete_service).to(
        receive(:calculate_pension).and_return(true)
      )

      allow(described_class).to(
        receive(:service_class).and_return(concrete_service)
      )

      concrete_service
    end

    context "when service is enabled" do
      let(:service_name) { "varias" }

      it "runs the concrete service" do
        expect(service_class).to receive(:calculate_pension).and_return(true)
        subject.call(questionnaire_response)
      end
    end

    context "when service is disabled" do
      let(:service_name) { nil }

      it "skips concrete service run" do
        expect(service_class).not_to receive(:calculate_pension)
        subject.call(questionnaire_response)
      end
    end
  end
end

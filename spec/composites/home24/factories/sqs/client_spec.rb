# frozen_string_literal: true

require "rails_helper"
require "composites/home24/factories/sqs/client"
require "composites/home24/outbound/sqs/fake_client"
require "composites/home24/outbound/sqs/client"

RSpec.describe Home24::Factories::Sqs::Client do
  let(:client) { described_class.build }

  describe ".build" do
    context "when env is not in production" do
      it "should return instance of fake client" do
        expect(client).to be_kind_of(Home24::Outbound::Sqs::FakeClient)
      end
    end

    context "when env is in production" do
      before do
        allow(Rails).to receive(:env) { "production".inquiry }
      end

      it "should return instance of real client" do
        expect(client).to be_kind_of(Home24::Outbound::Sqs::Client)
      end
    end
  end
end

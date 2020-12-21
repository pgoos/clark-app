# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::ApiPartners::QueueClient do
  describe ".get_client_instance" do
    let(:subject) { described_class.get_client_instance("test_partner") }

    context "development enviroment" do
      let(:env) { :development }
      let(:expected_class) { Platform::ApiPartners::Clients::MockClient }

      include_examples "queue_client"
    end

    context "test enviroment" do
      let(:env) { :test }
      let(:expected_class) { Platform::ApiPartners::Clients::MockClient }

      include_examples "queue_client"
    end

    context "production enviroment" do
      let(:env) { :production }
      let(:expected_class) { Platform::ApiPartners::Clients::AmazonSqs }

      include_examples "queue_client"
    end
  end
end

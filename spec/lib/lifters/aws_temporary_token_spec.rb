# frozen_string_literal: true

require "rails_helper"
require "lifters/aws_temporary_token"

RSpec.describe Lifters::AwsTemporaryToken do
  let(:admin) { build_stubbed(:admin) }
  let(:region) { "eu-central-1" }
  let(:session_token) { "session_token" }

  let(:client_double) { instance_double(Aws::STS::Client) }
  let(:token_response) do
    credentials = Aws::STS::Types::Credentials.new(
      session_token: session_token,
      expiration: "2019-01-22T12:25:47.000Z"
    )
    Aws::STS::Types::AssumeRoleResponse.new(credentials: credentials)
  end

  describe "#generate" do
    let(:bucket) { "bucket" }

    before do
      allow(Aws::STS::Client).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:assume_role).and_return(token_response)
    end

    it do
      subject = described_class.new(
        region: region,
        role: "role",
        duration: 10,
        bucket: "bucket"
      )
      token = subject.generate(admin)
      expect(token[:session_token]).to eq session_token
      expect(token[:region]).to eq region
      expect(token[:bucket]).to eq "bucket"

      expect(client_double).to \
        have_received(:assume_role)
        .with(role_arn: "role",
              role_session_name: admin.email,
              duration_seconds: 10)
    end
  end
end

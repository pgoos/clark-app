# frozen_string_literal: true

require "rails_helper"
require "lifters/ocr/temporary_token"

RSpec.describe Lifters::OCR::TemporaryToken do
  let(:admin) { build_stubbed(:admin) }
  let(:region) { "eu-central-1" }
  let(:session_token) { "session_token" }

  let(:client_double) { instance_double(Aws::STS::Client) }
  let(:profile_credentials) { instance_double(Aws::InstanceProfileCredentials) }
  let(:token_response) do
    credentials = Aws::STS::Types::Credentials.new(
      session_token: session_token,
      expiration: "2019-01-22T12:25:47.000Z"
    )
    Aws::STS::Types::AssumeRoleResponse.new(credentials: credentials)
  end

  describe "#generate" do
    let(:bucket) { Settings.ocr.upload.bucket }

    before do
      allow(Aws::STS::Client).to receive(:new).and_return(client_double)
      allow(Aws::InstanceProfileCredentials).to receive(:new).and_return(profile_credentials)
      allow(client_double).to receive(:assume_role).and_return(token_response)
    end

    it do
      subject = described_class.new(
        region: region,
        role: "role"
      )
      token = subject.generate(admin)
      expect(token[:session_token]).to eq session_token
      expect(token[:region]).to eq region
      expect(token[:bucket]).to eq Settings.ocr.upload.bucket

      expect(client_double).to \
        have_received(:assume_role)
        .with(role_arn: "role",
              role_session_name: admin.email,
              duration_seconds: Settings.ocr.upload.duration)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Service::Varias::Token do
  subject do
    described_class.new(
      partner_id: partner_id,
      partner_key: partner_key,
      user_id: user_id,
      user_key: user_key
    )
  end

  let(:partner_id) { "PARTNER_ID" }
  let(:partner_key) { "PARTNER_KEY" }
  let(:user_id) { "USER_ID" }
  let(:user_key) { "USER_KEY" }

  let(:encoded_token) do
    "eyJhbGciOiJIUzI1NiJ9."\
    "eyJzdWIiOiJVU0VSX0lEIiwiaXNzIjoiUEFSVE5FUl9JRCIsImlhdCI6MTU3NzgzMzIwMCwiZXhwIjoxNTc3ODMzMzgwfQ."\
    "MpY22rGyENPWIPRk12t7M0jy4gBIs5iDGmjvIhNTGcY"
  end

  describe ".initialize" do
    let(:expected_partner_secret) { { id: partner_id, key: partner_key } }
    let(:expected_user_secret) { { id: user_id, key: user_key } }

    it "assigns correct partner secret" do
      expect(subject.__send__(:partner_secret)).to eq(expected_partner_secret)
    end

    it "assigns correct user secret" do
      expect(subject.__send__(:user_secret)).to eq(expected_user_secret)
    end
  end

  describe "#encode" do
    it "returns encoded JWT token" do
      Timecop.freeze(Date.new(2020, 1, 1)) do
        expect(subject.encode).to eq(encoded_token)
      end
    end
  end

  describe "#decode" do
    it "returns decoded JWT token" do
      Timecop.freeze(Date.new(2020, 1, 1)) do
        expect(subject.decode(encoded_token)).to(
          include(
            a_hash_including(
              "sub" => user_id,
              "iss" => partner_id
            ),
            a_hash_including(
              "alg" => "HS256"
            )
          )
        )
      end
    end
  end
end

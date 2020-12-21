# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform::AppleSignIn do
  describe "#decode_jwt" do
    before do
      allow(Net::HTTP).to receive(:get).and_return(apple_auth_keys)
    end

    let(:apple_auth_keys) do
      File.read(Rails.root.join("spec", "fixtures", "apple_auth_keys"))
    end

    let(:jwt) do
      <<~JWT.gsub("\n", "")
        eyJraWQiOiI4NkQ4OEtmIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwb
        GUuY29tIiwiYXVkIjoiZGUuY2xhcmsuaW9zLmlwaG9uZS5jbGFyayIsImV4cCI6MTU5NjE5MDMxMSwia
        WF0IjoxNTk2MTg5NzExLCJzdWIiOiIwMDEwMTguYjNkMzRiMDVlNThhNGYxY2I5OGYwMmQxMTAxNWI5O
        WIuMTQyOCIsImNfaGFzaCI6ImVGbHRiS1ViY2lSalZHRUxQbzhEdGciLCJlbWFpbCI6ImVsdmlpbi5hc
        HBsZS5pZEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6InRydWUiLCJhdXRoX3RpbWUiOjE1OTYxO
        Dk3MTEsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.CRC0LPz7qNGQs24mBGrrXmiuzjYoPNs4OB0Ncl_5n
        jhYhQnuQPDugk1sLAoODgneyBUgqOcDe78TDFDCpqb-mMwZrNPzjBcdiirSTCDJaokD0k7QqFw9dJX4m
        7m778bf_VrmJAApZKERoQ5jlJ0K40BME397T4jjFNcwLyw5PK9Hc5-da_5xMD9-SVQtrJ2UqFAgxt2u0
        eLRhc9Lbddag0r87h04_IcviIDN1yUZO5kzgX0AR3v25CNGOG61qR60NLf7CJ5SP81tnXMYkcRPbmY13
        dI4Dcn6FOYXu2NG2wjT7WRvWgcDqOK97IBn3zeu_VqtJHH3YH7cSXQ_x8uC4A
      JWT
    end

    let(:jwt_data) do
      {
        "iss"             => "https://appleid.apple.com",
        "aud"             => "de.clark.ios.iphone.clark",
        "exp"             => 1_596_190_311,
        "iat"             => 1_596_189_711,
        "sub"             => "001018.b3d34b05e58a4f1cb98f02d11015b99b.1428",
        "c_hash"          => "eFltbKUbciRjVGELPo8Dtg",
        "email"           =>  "elviin.apple.id@gmail.com",
        "email_verified"  => "true",
        "auth_time"       => 1_596_189_711,
        "nonce_supported" => true
      }
    end

    it "raise exception if exp is over" do
      expect { described_class.decode_jwt(jwt) }.to raise_exception(JWT::ExpiredSignature)
    end

    it "returns token data" do
      Timecop.freeze(Time.at(1_596_190_310))

      expect(described_class.decode_jwt(jwt)).to eq(jwt_data)

      Timecop.freeze(Time.current)
    end
  end
end

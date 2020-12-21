# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmberController, :integration, type: :request do
  let(:android) do
    "Mozilla/5.0 (Linux; U; Android 6.0.1; en-us; Nexus 5 Build/FRG83) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
  end
  let(:ios) do
    "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
  end

  describe "#header" do
    it "should have http status 200" do
      get "/ember/header", params: {locale: :de}

      expect(response.status).to eq 200
    end
  end

  describe "#footer" do
    it "should have http status 200" do
      get "/ember/footer", params: {locale: :de}

      expect(response.status).to eq 200
    end
  end
end

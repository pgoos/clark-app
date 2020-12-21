# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Root do
  context "as storage of configuration" do
    it "contains unfreezed header tokens" do
      expect(ClarkAPI::V3::Root::AUTH_TOKEN_HEADER_DESC).not_to be_frozen
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ahoy cookie spec", :integration, type: :request do
  describe "returns the correct cookie" do
    it "sets the HttpOnly option" do
      # Hit unimportant endpoint just to pass through rails stack injecting ahoy cookies
      get "/de/heartbeat"

      expect(cookies.get_cookie("ahoy_visitor").http_only?).to eq false
      expect(cookies.get_cookie("ahoy_visit").http_only?).to eq false
    end
  end
end

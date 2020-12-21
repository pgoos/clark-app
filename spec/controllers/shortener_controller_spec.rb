# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShortenerController, :integration, type: :controller do
  describe "GET show" do
    before do
      allow(Shortener::ShortenedUrl)
        .to receive(:extract_token).with("ID").and_return("TOKEN")

      allow(Shortener::ShortenedUrl).to receive(:fetch_with_token)
        .with(
          token: "TOKEN",
          additional_params: {
            "foo"        => "bar",
            "id"         => "ID",
            "controller" => "shortener",
            "action"     => "show"
          },
          track: true
        )
        .and_return(url: "/SHORT_URL")

      get :show, params: {id: "ID", foo: :bar}
    end

    it "redirects to a short url" do
      expect(response).to redirect_to "/SHORT_URL"
    end
  end
end

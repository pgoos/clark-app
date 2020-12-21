# frozen_string_literal: true

RSpec.shared_examples "an authenticated api request" do |path|
  it "requires authentication" do
    logout
    json_post_v2 path, params
    expect(response.status).to eq(401)
  end

  it "provides an localized error message" do
    logout
    current_locale = I18n.locale

    %i[de en].each do |locale|
      I18n.locale = locale

      json_post_v2 path, params

      expect(json_response.error).to eq(I18n.t("grape.errors.messages.not_logged_in"))
    end

    I18n.locale = current_locale
  end
end

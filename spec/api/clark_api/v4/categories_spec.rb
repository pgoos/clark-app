# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Categories, :integration do
  describe "GET /api/categories/active" do
    it "returns active categories" do
      create :category, :regular,  :inactive, ident: "REGULAR_INACTIVE"
      create :category, :regular,  :active,   ident: "REGULAR_ACTIVE", search_tokens: "hello"

      create :category, :umbrella, :active, ident: "UMBRELLA_ACTIVE", included_category_ids: [
        create(:category, :regular, :active, ident: "U_FOO").id
      ]

      create :category, :umbrella, :inactive, ident: "UMBRELLA_INACTIVE", included_category_ids: [
        create(:category, :regular, :active, ident: "U_BAR").id
      ]

      create :category, :combo, :active, ident: "COMBO_ACTIVE", included_category_ids: [
        create(:category, :regular, :active, ident: "C_DISCONTINUED", discontinued: true).id
      ]

      json_get_v4 "/api/categories/active"

      expect(response.status).to eq(200)
      expect(json_response.categories.map(&:ident)).to \
        match_array %w[REGULAR_ACTIVE U_FOO U_BAR]

      expect(response.headers).to have_key("Etag")
      expect(response.headers).to have_key("Cache-Control")

      expect(json_response.categories.first.keys).to \
        match_array %w[id ident discontinued name name_hyphenated search_tokens life_aspect category_type]

      expect(json_response.categories.map(&:search_tokens)).to include(["hello"])

      json_get_v4 "/api/categories/active", include_umbrella: true
      expect(json_response.categories.map(&:ident)).to \
        match_array %w[REGULAR_ACTIVE UMBRELLA_ACTIVE U_FOO U_BAR]

      json_get_v4 "/api/categories/active", include_umbrella: true
      expect(json_response.categories.map(&:ident)).to \
        match_array %w[REGULAR_ACTIVE UMBRELLA_ACTIVE U_FOO U_BAR]

      json_get_v4 "/api/categories/active", include_umbrella: true, include_discontinued: true
      expect(json_response.categories.map(&:ident)).to \
        match_array %w[REGULAR_ACTIVE UMBRELLA_ACTIVE U_FOO U_BAR C_DISCONTINUED]
    end

    it "does not return discontinued categories" do
      create :category, :regular, :active, ident: "REGULAR_ACTIVE", discontinued: true
      json_get_v4 "/api/categories/active"

      expect(response.status).to eq(200)
      expect(json_response.categories.map(&:ident)).to eq []
    end
  end
end

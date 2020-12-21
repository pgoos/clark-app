# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Comparison::Gkv::GkvProvider do
  it "only defines provinces that exists in germany" do
    existing_provinces = GERMAN_PLACES.provinces.map{|p| [p, true]}.to_h

    all_providers = Domain::Comparison::Gkv::GkvProvider::GKV_PROVIDERS_REGION
    restricted_providers = all_providers.reject{ |p| p[1].member?(:whole_nation) }

    restricted_providers.each do |provider, provinces|
      provinces.each do |province|
        error_msg = "Province #{province} is not a valid name for company_id #{provider}"
        expect(existing_provinces[province]).to eq(true), error_msg
      end
    end
  end
end

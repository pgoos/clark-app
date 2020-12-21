# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Company do
  include ClarkAPI::Helpers::CompanyHelpers

  subject { described_class }

  let(:company) { FactoryBot.build_stubbed(:company) }

  it { is_expected.to expose(:id).of(company).as(Integer) }
  it { is_expected.to expose(:name).of(company).as(String) }

  it do
    is_expected.to expose(:name_hyphenated).of(company)
      .with_value(word_hypen(company.name)).as(String)
  end

  it { is_expected.to expose(:average_response_time).of(company).as(Integer) }
  it { is_expected.to expose(:details).of(company).with_value(company_details(company)).as(Hash) }

  # FIXME: Company as Hash vs Hash
  # it do
  #   default_url = ActionController::Base.helpers.asset_path("im-shield.png")
  #   expected_serialization = { "url" => default_url, tiny: {"url" => default_url, thumb: {"url" => default_url}}}
  #   is_expected.to expose(:logo).of(company).with_value(expected_serialization).as(HashWithIndifferentAccess)
  # end
end

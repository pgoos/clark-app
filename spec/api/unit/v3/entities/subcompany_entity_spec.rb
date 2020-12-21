# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Subcompany do
  subject { described_class }
  let(:subcompany) { FactoryBot.build_stubbed(:subcompany) }

  it { is_expected.to expose(:id).of(subcompany).as(Integer) }
  it { is_expected.to expose(:name).of(subcompany).as(String) }
  it { is_expected.to expose(:metadata).of(subcompany).as(Hash) }
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Concerns::IdExposable do
  subject { ClarkAPI::V3::Entities::Company }
  let(:object) { FactoryBot.build_stubbed(:company) }

  it { is_expected.to expose(:id).of(object).as(Integer) }
end

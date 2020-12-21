# frozen_string_literal: true

FactoryBot.define do
  factory :nps_interaction do
    mandate
    nps_cycle
    nps
  end
end

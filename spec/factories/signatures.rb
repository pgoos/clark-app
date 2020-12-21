# frozen_string_literal: true

# == Schema Information
#
# Table name: signatures
#
#  id            :integer          not null, primary key
#  signable_id   :integer
#  signable_type :string
#  asset         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :signature do
    association :signable, factory: :mandate
    asset { Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path) }
  end
end

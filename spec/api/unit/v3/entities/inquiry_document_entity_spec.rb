# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::InquiryDocument do
  subject { described_class }
  let(:document) { FactoryBot.build_stubbed(:document, :with_qualitypool_transfer) }

  it do
    is_expected.to expose(:asset).of(document)
      .with_value("url" => document.asset.url).as(Hash).use_root_key(:document)
  end

  it { is_expected.to expose(:content_type).of(document).as(String).use_root_key(:document) }
  it { is_expected.to expose(:size).of(document).as(Integer).use_root_key(:document) }
  it { is_expected.to expose(:documentable_id).of(document).as(Integer).use_root_key(:document) }
  it { is_expected.to expose(:documentable_type).of(document).as(String).use_root_key(:document) }

  it do
    is_expected.to expose(:created_at).of(document)
      .with_value(f_date(document.created_at)).as(String).use_root_key(:document)
  end

  it do
    is_expected.to expose(:updated_at).of(document)
      .with_value(f_date(document.updated_at)).as(String).use_root_key(:document)
  end

  it { is_expected.to expose(:document_type_id).of(document).as(Integer).use_root_key(:document) }
  it { is_expected.to expose(:metadata).of(document).as(Hash).use_root_key(:document) }
  it { is_expected.not_to expose(:qualitypool_id).of(document).use_root_key(:document) }

  it do
    filename = document.asset.path.split("/").last
    is_expected.to expose(:filename).of(document)
      .with_value(filename).as(String).use_root_key(:document)
  end

  def f_date(date_time)
    I18n.l(date_time, format: :date)
  end
end

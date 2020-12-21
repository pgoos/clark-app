# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::CategoryPage do
  subject { described_class }

  let(:category) { create(:category, :category_page) }

  it { is_expected.to expose(:benefits).of(category).with_value(category.benefits).as(Array) }
  it { is_expected.to expose(:clark_warranty).of(category).with_value(category.clark_warranty).as(Array) }
  it { is_expected.to expose(:consultant_comment).of(category).with_value(category.consultant_comment).as(String) }
  it { is_expected.to expose(:cover_benchmark).of(category).with_value(category.cover_benchmark).as(Integer) }
  it { is_expected.to expose(:description).of(category).with_value(category.customer_description).as(String) }
  it { is_expected.to expose(:number_companies).of(category).with_value(category.number_companies).as(String) }
  it { is_expected.to expose(:number_plans).of(category).with_value(category.number_plans).as(String) }
  it { is_expected.to expose(:post_purchase_satisfaction).of(category).with_value(category.post_purchase_satisfaction).as(String) }
  it { is_expected.to expose(:price_benchmark).of(category).with_value(category.price_benchmark).as(String) }
  it { is_expected.to expose(:priority).of(category).with_value(category.priority).as(Integer) }
  it { is_expected.to expose(:rating_criteria).of(category).with_value(category.rating_criteria).as(Array) }
  it { is_expected.to expose(:selection_guidelines).of(category).with_value(category.selection_guidelines).as(Array) }
  it { is_expected.to expose(:time_to_offer).of(category).with_value(category.time_to_offer).as(String) }
  it { is_expected.to expose(:what_happens_if).of(category).with_value(category.what_happens_if).as(String) }

  it do
    is_expected.to expose(:quality_standards).of(category)
                                             .with_value(title: category.quality_standards_title,
                                                         features: category.quality_standards_features)
                                             .as(Hash)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::Todo do
  subject { described_class }

  let(:category) { build_stubbed(:bu_category) }
  let(:recommendation) { build_stubbed(:recommendation, category: category) }

  it { is_expected.to expose(:category_ident).of(recommendation).as(String).with_value(recommendation.category_ident) }
  it { is_expected.to expose(:description).of(recommendation).as(String).with_value(I18n.t("category_pages." + recommendation.category_ident + ".consultant_comment")) }
  it { is_expected.to expose(:price_benchmark).of(recommendation).as(String).with_value(I18n.t("category_pages." + recommendation.category_ident + ".price_benchmark")) }
  it { is_expected.to expose(:benefits).of(recommendation).as(Array).with_value(I18n.t("category_pages." + recommendation.category_ident + ".benefits"))}

  context "details_from_db setting is set to true" do
    before do
      allow(Settings).to receive_message_chain(:clark_api, :category_pages, :details_from_db).and_return(true)
    end

    let(:category) { build_stubbed(:category, :category_page) }

    it { is_expected.to expose(:description).of(recommendation).as(String).with_value(recommendation.category.consultant_comment) }
    it { is_expected.to expose(:price_benchmark).of(recommendation).as(String).with_value(recommendation.category.price_benchmark) }
    it { is_expected.to expose(:benefits).of(recommendation).as(Array).with_value(recommendation.category.benefits) }
  end
end

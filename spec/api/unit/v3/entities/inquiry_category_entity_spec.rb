# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::InquiryCategory do
  subject { described_class }

  let(:inquiry_category) { create(:inquiry_category) }
  let(:document) { build_stubbed(:document, documentable: inquiry_category) }

  it { is_expected.to expose(:category_ident).of(inquiry_category).as(String) }
  it { is_expected.to expose(:company_ident).of(inquiry_category).as(String) }
  it { is_expected.to expose(:documents).of(inquiry_category).as(Array) }

  context "total_evaluation", :integration do
    let!(:instant_advice) do
      create(:instant_assessment,
             company_ident: inquiry_category.inquiry.company.ident,
             category_ident: inquiry_category.category.ident)
    end
    let(:inquiry_category) { create(:inquiry_category) }
    let(:response_obj) { double :response_obj }

    before do
      allow(Customer).to receive(:instant_advice_permitted?).and_return(response_obj)
    end

    it "returns nil when customer isn't permitted" do
      allow(response_obj).to receive(:failure?).and_return(true)
      expect(total_evaluation(inquiry_category)).to eq nil
    end

    it "returns total_evaluation when customer is permitted" do
      allow(response_obj).to receive(:failure?).and_return(false)
      expect(total_evaluation(inquiry_category)).to eq(
        I18n.t("composites.contracts.constituents.instant_advice.mapping.average")
      )
    end

    def total_evaluation(inquiry_category)
      result(inquiry_category)[:total_evaluation]
    end

    def result(inquiry_category)
      described_class.new(inquiry_category).as_json
    end
  end
end

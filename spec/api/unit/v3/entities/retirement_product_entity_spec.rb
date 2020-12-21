# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V3::Entities::RetirementProduct do
  subject { described_class }

  context "retirement_product" do
    let(:retirement_product) { FactoryBot.build_stubbed(:retirement_product) }

    it { is_expected.to expose(:id).of(retirement_product).as(Integer) }
  end

  context "retirement_equity_product" do
    let(:retirement_product) { FactoryBot.build_stubbed(:retirement_equity_product) }

    it { is_expected.to expose(:id).of(retirement_product).as(Integer) }
    it { is_expected.to expose(:type).of(retirement_product).as(String) }
    it { is_expected.to expose(:equity_today_cents).of(retirement_product).as(Integer) }
  end
end

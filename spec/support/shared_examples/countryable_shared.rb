# frozen_string_literal: true

RSpec.shared_examples "a countrifiable model" do
  let(:model) { build ActiveModel::Naming.singular(described_class) }

  before {
    @remembered_locale = I18n.locale
    I18n.locale        = :en
  }

  after { I18n.locale = @remembered_locale }

  %i[country_code country country_name].each do |attr|
    it { expect(model).to be_respond_to(attr) }
  end

  context "when country code is DE" do
    before { model.country_code = "DE" }
    it { expect(model.country).to eq ISO3166::Country["DE"] }
  end

  context "when country code is GB" do
    before { model.country_code = "GB" }
    it { expect(model.country).to eq ISO3166::Country["GB"] }
  end
end

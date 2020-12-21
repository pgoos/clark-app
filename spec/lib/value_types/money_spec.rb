# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValueTypes::Money do

  context "#to_monetized" do
    it 'should allow to monetize' do
      expect(ValueTypes::Money.new(1.1, 'EUR').to_monetized).to be_a_kind_of(::Money)
    end

    it 'should monetize to the same value 1.10 EUR' do
      value_types_money = ValueTypes::Money.new(1.1, 'EUR')
      monetized         = value_types_money.to_monetized
      expect(ValueTypes::Money.new(monetized.to_f, monetized.currency.to_s)).to eq(value_types_money)
    end

    it 'should monetize to the same value 21.13 USD' do
      value_types_money = ValueTypes::Money.new(21.13, 'USD')
      monetized         = value_types_money.to_monetized
      expect(ValueTypes::Money.new(monetized.to_f, monetized.currency.to_s)).to eq(value_types_money)
    end

    it 'should handle string values properly' do
      value_types_money = ValueTypes::Money.new('21.13', 'EUR')
      expect(value_types_money.to_monetized.cents).to eq(2113)
    end
  end

  context "#to_s" do
    before do
      @reset_locale = I18n.locale
      I18n.locale = :de
    end

    after do
      I18n.locale = @reset_locale
    end

    it "should to_s with a precision of 2" do
      value_types_money = ValueTypes::Money.new('21.13', 'EUR')
      expect(value_types_money.to_s).to eq("21,13 €")
    end
  end

end

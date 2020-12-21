require 'rails_helper'

describe Qualitypool::Mappings do
  let(:subject) { Qualitypool::Mappings }

  it 'converts ISO3166 country code to GDV code' do
    Qualitypool::Mappings::ISO3166_TO_GDV.each do |iso_code, gdv_code|
      expect(subject.country_iso3166_to_gdv(iso_code)).to eq(gdv_code)
    end
  end

  it 'converts a datetime object to the ST_Datumzeit format' do
    expect(subject.datetime_to_st_datumzeit(DateTime.new(2016, 6, 15, 13, 45, 0))).to eq('2016-06-15T13:45')
  end

  context 'gender -> anrede' do
    it { expect(subject.gender_to_anrede('male')).to eq('1') }
    it { expect(subject.gender_to_anrede('female')).to eq('2') }
    it { expect(subject.gender_to_anrede('company')).to eq('0') }
    it { expect(subject.gender_to_anrede('other')).to be_nil }
  end

  context 'gender -> geschlecht' do
    it { expect(subject.gender_to_geschlecht('male')).to eq('1') }
    it { expect(subject.gender_to_geschlecht('female')).to eq('2') }
    it { expect(subject.gender_to_geschlecht('other')).to be_nil }
  end

  context 'product.premium_state -> ST_Vertragsstatus' do
    # On-Hold state is currently not supported by Hypoport Platform
    #it { expect(subject.product_state_to_status(Product.new(premium_state: 'on_hold'))).to eq('6') }

    it { expect(subject.product_state_to_status(Product.new(premium_state: 'premium'))).to eq('1') }
    it { expect(subject.product_state_to_status(Product.new(premium_state: 'salary'))).to eq('1') }
  end

  context 'category.premium_type -> STE_Beitrag' do
    it { expect(subject.product_premium_type_to_art_id(double(Product, category: Category.new(premium_type: 'gross')))).to eq('01') }
    it { expect(subject.product_premium_type_to_art_id(double(Product, category: Category.new(premium_type: 'net')))).to eq('02') }
  end

  context 'subcompany -> CT_Unternehmen' do
    it 'uses BaFin ID when present' do
      result = subject.subcompany_to_unternehmen(double(Subcompany, bafin_id: 1234, qualitypool_ident: nil))

      expect(result[:Nummernart]).to eq('BaFin')
      expect(result[:Nummer]).to eq('1234')
    end

    it 'uses Qualitypool Ident when present' do
      result = subject.subcompany_to_unternehmen(double(Subcompany, bafin_id: nil, qualitypool_ident: 'U001234'))

      expect(result[:Nummernart]).to eq('GPID')
      expect(result[:Nummer]).to eq('U001234')
    end

    it 'uses Qualitypool Ident when both are present' do
      result = subject.subcompany_to_unternehmen(double(Subcompany, bafin_id: 1234, qualitypool_ident: 'U001234'))

      expect(result[:Nummernart]).to eq('GPID')
      expect(result[:Nummer]).to eq('U001234')
    end
  end

  context 'Money -> ST_Betrag' do
    it { expect(subject.money_to_betrag(Money.new(24_99, 'EUR'))).to eq(24.99) }
    it { expect(subject.money_to_betrag(24.99)).to eq(24.99) }
  end

  context 'Money -> ST_Waehrungsschluessel' do
    it 'uses the currency when a money value is provided' do
      expect(subject.money_to_waehrung(Money.new(24_99, 'USD'))).to eq('USD')
    end

    it 'assumes EUR when only a float is provided' do
      expect(subject.money_to_waehrung(24.99)).to eq('EUR')
    end
  end

  it 'builds product details from category and plan name' do
    product = FactoryBot.build(:product, :publishable)
    expect(subject.product_details_to_bezeichnung(product)).to eq("#{product.category.name} - #{product.plan.name}")
  end

  context 'Category -> Plattform_Produktkennung' do
    let!(:category) { create(:category) }

    %w[d9c5a3fe f729a5c6 d6b6cbd3 d55e03e6 c1f180cd].each do |category_ident|
      it "KFZ for products of category ident #{category_ident}" do
        category.update_attributes(ident: category_ident)
        expect(subject.category_to_sparte(category)).to include(sparte: "050", produkt_typ: nil)
      end
    end

    it {
      expect(subject.category_to_sparte(build(:category, ident: "f6304763")))
        .to include(sparte: "010", produkt_typ: "Dread Disease")
    }
    it {
      expect(subject.category_to_sparte(build(:category, ident: "1b1d278a")))
        .to include(sparte: "010", produkt_typ: "SBU")
    }
    it { expect(subject.category_to_sparte(build(:category, ident: "9e0b37f2"))[:sparte]).to eq("176") }
    it { expect(subject.category_to_sparte(build(:category, ident: "smartphone"))[:sparte]).to eq("172") }
    it { expect(subject.category_to_sparte(build(:category, ident: "0a6fc604"))[:sparte]).to eq("172") }
    it { expect(subject.category_to_sparte(build(:category, ident: "6f47b7ea"))[:sparte]).to eq("172") }
    it { expect(subject.category_to_sparte(build(:category, ident: "26c8058b"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "47a1b441"))[:sparte]).to eq("140") }
    it { expect(subject.category_to_sparte(build(:category, ident: "98a575ee"))[:sparte]).to eq("140") }
    it { expect(subject.category_to_sparte(build(:category, ident: "feuerrohbau"))[:sparte]).to eq("140") }
    it { expect(subject.category_to_sparte(build(:category, ident: "76ebd870"))[:sparte]).to eq("140") }
    it { expect(subject.category_to_sparte(build(:category, ident: "c37ae89a"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "06f05bb7"))[:sparte]).to eq("110") }
    it { expect(subject.category_to_sparte(build(:category, ident: "f47677cc"))[:sparte]).to eq("110") }
    it { expect(subject.category_to_sparte(build(:category, ident: "IThaft"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "phv-sas"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "ddf15226"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "7d4ba255"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "7afbebb8"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "498acfae"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "78c8fa55"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "518851f3"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "ad4ba969"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "f154d351"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "03b12732"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "8a0f9180"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "12d09148"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "ac4b1d75"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "19955c67"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "7c009dca"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "d2583b1a"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "a011903a"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "5792c597"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "8b2b3281"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "dcd2413c"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "afe225d9"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "e71aa6fa"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "vshaftpflicht"))[:sparte]).to eq("040") }
    it { expect(subject.category_to_sparte(build(:category, ident: "e251294f"))[:sparte]).to eq("130") }
    it { expect(subject.category_to_sparte(build(:category, ident: "19591a9e"))[:sparte]).to eq("130") }
    it { expect(subject.category_to_sparte(build(:category, ident: "ede34b57"))[:sparte]).to eq("130") }
    it { expect(subject.category_to_sparte(build(:category, ident: "b35689d5"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "be524008"))[:sparte]).to eq("201") }
    it { expect(subject.category_to_sparte(build(:category, ident: "1bbdbb5e"))[:sparte]).to eq("070") }
    it { expect(subject.category_to_sparte(build(:category, ident: "5bfa54ce"))[:sparte]).to eq("070") }
    it { expect(subject.category_to_sparte(build(:category, ident: "vermieter-rs"))[:sparte]).to eq("070") }
    it { expect(subject.category_to_sparte(build(:category, ident: "5085b48f"))[:sparte]).to eq("030") }
    it { expect(subject.category_to_sparte(build(:category, ident: "03f92107"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "b5c95780"))[:sparte]).to eq("030") }
    it { expect(subject.category_to_sparte(build(:category, ident: "cf064be0"))[:sparte]).to eq("030") }
    it { expect(subject.category_to_sparte(build(:category, ident: "08e4af50"))[:sparte]).to eq("684") }
    it { expect(subject.category_to_sparte(build(:category, ident: "4eda0a94"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "960fbe06"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "74f13ae8"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "84c9d04a"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "72e5556c"))[:sparte]).to eq("020") }
    it { expect(subject.category_to_sparte(build(:category, ident: "bc4ea252"))[:sparte]).to eq("294") }
    it { expect(subject.category_to_sparte(build(:category, ident: "a37cd85a"))[:sparte]).to eq("050") }
    it { expect(subject.category_to_sparte(build(:category, ident: "6f32ac15"))[:sparte]).to eq("020") }
  end

  context 'Premium Period -> ST_Zahlungsweise' do
    it { expect(subject.product_premium_period_to_zahlungsweise(Product.new(premium_period: 'month'))).to eq('8') }
    it { expect(subject.product_premium_period_to_zahlungsweise(Product.new(premium_period: 'quarter'))).to eq('4') }
    it { expect(subject.product_premium_period_to_zahlungsweise(Product.new(premium_period: 'half_year'))).to eq('2') }
    it { expect(subject.product_premium_period_to_zahlungsweise(Product.new(premium_period: 'year'))).to eq('1') }
    it { expect(subject.product_premium_period_to_zahlungsweise(Product.new(premium_period: 'once'))).to eq('6') }
  end

  context 'Annual Maturity -> Plattform_MonatTag' do
    it { expect(subject.product_maturity_to_faelligkeit(Product.new(annual_maturity: { day: 31, month: 10}))). to eq('10-31')}
  end
end

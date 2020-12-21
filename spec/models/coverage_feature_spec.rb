require 'rails_helper'

RSpec.describe CoverageFeature, type: :model do

  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  it_behaves_like "a localizable model"
  # State Machine
  # Scopes
  # Associations
  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:identifier) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:definition) }
  it { expect(subject).to validate_inclusion_of(:value_type).in_array(ValueTypes.types.map(&:to_s)) }
  it { expect(subject).to allow_value(nil).for(:genders) }
  it { expect(subject).to allow_value([]).for(:genders) }
  it { expect(subject).to allow_value([:female]).for(:genders) }
  it { expect(subject).to allow_value([:male]).for(:genders) }
  it { expect(subject).to allow_value([:female, :male]).for(:genders) }
  it { expect(subject).to_not allow_value([:wrong]).for(:genders) }

  # Callbacks

  context 'generate_identifier' do
    it 'generates an identifier based on the name' do
      name = 'Deckungssumme'
      definition = 'Definition'
      expect(Digest::SHA1).to receive(:hexdigest).with("#{name}#{definition}").and_return('abcd1234')
      expect(CoverageFeature.new(name: name, definition: definition, value_type: :Money).identifier).to eq('money_dckngssmm_abcd12')
    end
  end

  # Instance Methods

  context 'ActiveModel::Serialization' do

    it 'serializes to JSON' do
      name = 'Deckungssumme'
      definition = 'Some Text'
      coverage_feature = CoverageFeature.new(name: name, definition: definition, value_type: :Money)
      digest_postfix = Digest::SHA1.hexdigest("#{name}#{definition}")[0..5]
      expected_json = '{"identifier":"money_dckngssmm_' + digest_postfix +
        '","name":"Deckungssumme","definition":"Some Text","valid_from":null,"valid_until":null,' \
        '"value_type":"Money","genders":null,"order":null,"section":null,"description":null}'
      expect(coverage_feature.to_json).to eq(expected_json)
    end
  end

  context 'gender' do
    it 'allows all genders, if no gender has been set' do
      coverage_feature = FactoryBot.build(:coverage_feature)
      expect(coverage_feature.fits_gender?(:male)).to be_truthy
      expect(coverage_feature.fits_gender?('male')).to be_truthy
      expect(coverage_feature.fits_gender?(:female)).to be_truthy
      expect(coverage_feature.fits_gender?('female')).to be_truthy
    end

    it 'allows the female gender, if it has been set' do
      coverage_feature = FactoryBot.build(:coverage_feature, genders: ['female'])
      expect(coverage_feature.fits_gender?(:male)).to be_falsey
      expect(coverage_feature.fits_gender?('male')).to be_falsey
      expect(coverage_feature.fits_gender?(:female)).to be_truthy
      expect(coverage_feature.fits_gender?('female')).to be_truthy
    end

    it 'allows the male gender, if it has been set' do
      coverage_feature = FactoryBot.build(:coverage_feature, genders: ['male'])
      expect(coverage_feature.fits_gender?(:male)).to be_truthy
      expect(coverage_feature.fits_gender?('male')).to be_truthy
      expect(coverage_feature.fits_gender?(:female)).to be_falsey
      expect(coverage_feature.fits_gender?('female')).to be_falsey
    end

    it 'allows the both genders, if it has been set as an empty array' do
      coverage_feature = FactoryBot.build(:coverage_feature, genders: [])
      expect(coverage_feature.fits_gender?(:male)).to be_truthy
      expect(coverage_feature.fits_gender?('male')).to be_truthy
      expect(coverage_feature.fits_gender?(:female)).to be_truthy
      expect(coverage_feature.fits_gender?('female')).to be_truthy
    end

  end

  describe "#active?" do
    let(:coverage_feature) { FactoryBot.build(:coverage_feature, valid_from: valid_from, valid_until: valid_until) }

    context "both valid_from and valid_until are nil" do
      let(:valid_from) { nil }
      let(:valid_until) { nil }

      it "return true" do
        expect(coverage_feature.active?).to eq(true)
      end
    end

    context "valid_from is future date" do
      let(:valid_from) { Date.tomorrow }
      let(:valid_until) { nil }

      it "return false" do
        expect(coverage_feature.active?).to eq(false)
      end
    end

    context "valid_until is past date" do
      let(:valid_from) { nil }
      let(:valid_until) { Date.yesterday }

      it "return false" do
        expect(coverage_feature.active?).to eq(false)
      end
    end

    context "valid_from and valid_until contain invalid value" do
      let(:valid_from) { "invalid" }
      let(:valid_until) { "invalid" }

      it "return true" do
        expect(coverage_feature.active?).to eq(true)
      end
    end
  end

  # Class Methods

end


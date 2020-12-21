require 'rails_helper'

describe ValueTypes::TypedEnum do

  before do
    ValueTypes.typed_enum :SomeEnum, %w( VALUE_1 VALUE_2 )
  end

  after do
    ValueTypes.send(:remove_const, :SomeEnum)
  end

  context 'active record' do
    it 'provides the sample enum values for active record' do
      expect(ValueTypes::SomeEnum.for_active_record).to include(value_1: 'value_1', value_2: 'value_2')
    end

    it 'provides the rating enum values for active record' do
      expect(ValueTypes::Rating.for_active_record).to include(r_0: 'r_0', r_1: 'r_1', r_2: 'r_2', r_3: 'r_3', r_4: 'r_4', r_5: 'r_5')
    end
  end

  context 'parses hashes to objects' do
    it 'returns nil if not all fields on the value type are filled out' do
      expect(ValueTypes.from_hash('some_enum', {})).to eq(nil)
    end

    it 'correctly parses an enum type' do
      expect(ValueTypes.from_hash('some_enum', {value: 'VALUE_1'})).to eq(ValueTypes::SomeEnum::VALUE_1)
    end

    it 'has to serialize to a parseable value hash' do
      hash = ValueTypes::SomeEnum::VALUE_1.to_h
      expect(hash).to eq({value: 'VALUE_1'})
      expect(ValueTypes.from_hash('some_enum', hash)).to be(ValueTypes::SomeEnum::VALUE_1)
    end

    it 'has to serialize to a struct like hash' do
      stuct_like_hash = ValueTypes::SomeEnum::VALUE_1.to_typed_h
      expect(stuct_like_hash).to eq({some_enum: {value: 'VALUE_1'}})
    end

    it 'has to provide a string serialization' do
      expect(ValueTypes::SomeEnum::VALUE_1.to_serialized_s).to eq('ValueTypes::SomeEnum::VALUE_1')
    end
  end

  context 'behaves like a renum' do
    it 'should know the value name' do
      expect(ValueTypes::Boolean::TRUE.name).to eq("TRUE")
    end

    it 'should deliver the right class for the value' do
      expect(ValueTypes::Boolean::TRUE.class).to eq(ValueTypes::Boolean)
    end

    it 'should deliver the modulized class name' do
      expect(ValueTypes::Boolean::TRUE.class.name).to eq("ValueTypes::Boolean")
    end

    it 'should provide an integer value' do
      expect(ValueTypes::Boolean::TRUE.to_i).to eq(0)
      expect(ValueTypes::Boolean::FALSE.to_i).to eq(1)
    end

    it 'should be a kind of renum' do
      expect(ValueTypes.is_kind_of_renum?(ValueTypes::Boolean)).to be_truthy
      expect(ValueTypes.is_kind_of_renum?(ValueTypes::Boolean::TRUE.class)).to be_truthy
    end
  end

  context 'localized values' do
    before :each do
      @current_locale = I18n.locale
      I18n.locale = :de
    end

    after :each do
      I18n.locale = @current_locale
    end

    it 'should return internationalized values' do
      expect(ValueTypes::Boolean::TRUE.to_s).to eq('Ja')
      expect(ValueTypes::Boolean::FALSE.to_s).to eq('Nein')
    end
  end
end
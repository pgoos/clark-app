# == Schema Information
#
# Table name: profile_properties
#
#  id          :integer          not null, primary key
#  identifier  :string
#  name        :string
#  description :string
#  value_type  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe ProfileProperty, :slow, type: :model do

  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  it_behaves_like 'an auditable model'

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Scopes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it { expect(subject).to have_many(:questions) }

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  [:name, :identifier, :description, :value_type].each do |field|
    it { expect(subject).to validate_presence_of(field) }
  end
  it { expect(subject).to validate_inclusion_of(:value_type).in_array(ValueTypes.types.map(&:to_s)) }

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  context '#generate_identifier on create' do
    it 'calls the #generate_identifier method on create' do
      expect(subject).to receive(:generate_identifier)

      subject.run_callbacks(:validation)
    end

    it 'generates an identifier based on the property name if none is set' do
      property = ProfileProperty.new(name: 'Some Property', value_type: 'Text', description: 'some text')
      property.send(:generate_identifier)

      expect(property.identifier).to eq('text_smprprty_37aa63')
    end

    it 'does not generate an identifier if one is present' do
      property = ProfileProperty.new(name: 'Some Property', identifier: 'id123', value_type: 'Text', description: 'some text')
      property.send(:generate_identifier)

      expect(property.identifier).to eq('id123')
    end
  end

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  context '#update_profile_for' do

    let(:mandate) { create(:mandate) }
    let(:profile_property) { create(:profile_property) }

    it 'creates a new ProfileDatum if it is not present' do
      expect {
        profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some Value'), source: 'something')
      }.to change { mandate.profile_data.count }.from(0).to(1)
    end

    it 'sets all data correctly in the ProfileDatum' do
      profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some Value'), source: 'something')

      data = mandate.profile_data.last
      expect(data.property_identifier).to eq(profile_property.identifier)
      expect(data.property).to eq(profile_property)
      expect(data.source).to eq('something')
      expect(data.value['text']).to eq('Some Value')
    end

    it 'does not create a new ProfileDatum if it is present' do
      profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some Value'), source: 'something')

      expect {
        profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some New Value'), source: 'something else')
      }.to_not change { mandate.profile_data.count }
    end

    it 'sets all data correctly in the ProfileDatum' do
      old_profile_datum = profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some Value'), source: 'something')
      profile_property.update_profile_for(mandate, ValueTypes::Text.new('Some New Value'), source: 'something else')

      data = mandate.profile_data.last
      expect(data.id).to eq(old_profile_datum.id)

      expect(data.property_identifier).to eq(profile_property.identifier)
      expect(data.property).to eq(profile_property)
      expect(data.source).to eq('something else')
      expect(data.value['text']).to eq('Some New Value')
    end
  end

  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

end

# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.shared_context "with management api adapter" do
  def mock_object(attributes)
    object = double("object_for_serialization")

    attributes.each do |attribute_name, attribute_value|
      if attribute_value.is_a? Hash
        allow(object).to(
          receive(attribute_name).and_return(
            mock_object(attribute_value)
          )
        )
      else
        allow(object).to(
          receive(attribute_name).and_return(attribute_value.to_s)
        )
      end
    end

    object
  end

  let(:object_for_serialization) do
    attributes = {id: 1}

    if described_class.const_defined? "ATTRIBUTES"
      attributes.merge!(
        described_class::ATTRIBUTES.zip(
          described_class::ATTRIBUTES
        ).to_h
      )
    end

    unless override_attributes.empty?
      attributes.merge!(override_attributes)
    end

    mock_object(attributes)
  end

  let(:override_attributes) do
    {}
  end

  let(:serializer) { described_class.new(object_for_serialization) }
  let(:adapter) { ActiveModelSerializers::Adapter.create(serializer, {}) }
  let(:serializable_hash) { adapter.serializable_hash }

  before(:all) do
    ActiveModelSerializers.config.adapter = :json_api
    ActiveModelSerializers.config.key_transform = :unaltered
  end

  after(:all) do
    ActiveModelSerializers.config.adapter = :attributes
    ActiveModelSerializers.config.key_transform = nil
  end
end
# rubocop:enable Metrics/BlockLength

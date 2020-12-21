# frozen_string_literal: true

RSpec.shared_examples "a localizable model" do
  let(:instance_name) { ActiveModel::Naming.singular(described_class) }
  let!(:instance) { build(instance_name) }

  context ".localized_attributes" do
    it "responds to the static method :localized_attributes" do
      expect { described_class.localized_attributes }.not_to raise_error
    end

    it "returns an array for :localized_attributes" do
      expect(described_class.localized_attributes).to be_a(Array)
    end

    it "does not return an empty array for :localized_attributes" do
      expect(described_class.localized_attributes.any?).to be_truthy
    end

    it "returns elements of type symbol" do
      expect(described_class.localized_attributes).to all(be_a(Symbol))
    end
  end


  context "generated methods" do
    it "generates a localized setter for localized attributes" do
      described_class.localized_attributes.each do |localized_attribute|
        Localizable::ALLOWED_LOCALES.each do |locale|
          expect {
            instance.send("#{localized_attribute}_#{locale}=","translated_text")
          }.not_to raise_error
        end
      end
    end

    it "generates a localized getter for localized attributes" do
      described_class.localized_attributes.each do |localized_attribute|
        Localizable::ALLOWED_LOCALES.each do |locale|
          expect {
            instance.send("#{localized_attribute}_#{locale}")
          }.not_to raise_error
        end
      end
    end
  end

  context "#maintain_translations" do
    let(:localized_attribute_name) { "#{described_class.localized_attributes.first}_#{Localizable::ALLOWED_LOCALES.first}" }
    it "creates a new translations record for the translated value" do
      instance.send("#{localized_attribute_name}=", "translation")
      expect { instance.maintain_translations }.to change { Translation.count }.by(1)
    end

    it "does not create a new translations record for the translated value if it was translated before" do
      instance.send("#{localized_attribute_name}=", "translation")
      instance.maintain_translations
      expect { instance.maintain_translations }.not_to change { Translation.count }
    end

    it "gets the translated value from translations table when getter is called" do
      instance.send("#{localized_attribute_name}=", "translation")
      instance.maintain_translations
      new_translation = "new translation"
      new_translation_hash = {
        Localizable::ALLOWED_LOCALES.first => new_translation
      }
      Translation.last.update_attributes(locales: new_translation_hash)
      expect(instance.send("#{localized_attribute_name}")).to eq(new_translation)
    end
  end
end

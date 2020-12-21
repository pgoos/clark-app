# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::Event do
  it { is_expected.to belong_to(:recognition) }

  it do
    expect(subject).to define_enum_for(:event_type).with(
      [
        OCR::Event::DOCUMENT_UPLOADED,
        OCR::Event::OCR_RECOGNITION_STARTED,
        OCR::Event::PRODUCT_VALIDATION_STARTED,
        OCR::Event::PRODUCT_VALIDATION_FAILED,
        OCR::Event::PRODUCT_VALIDATION_SUCCEDED,
        OCR::Event::PRODUCT_CREATION_SUCCEDED
      ]
    )
  end
end

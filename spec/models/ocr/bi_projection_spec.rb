# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCR::BIProjection do
  it { is_expected.to belong_to(:recognition) }
  it { is_expected.to belong_to(:recognizable) }
  it { is_expected.to validate_uniqueness_of(:recognizable_id).scoped_to(:recognizable_type).allow_blank }
end

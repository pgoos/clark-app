# frozen_string_literal: true

require "rails_helper"
require "lib/lifters/domain/order_automation/cover_note/shared_cover_note_expectations"

RSpec.describe Domain::OrderAutomation::CoverNote::PrepareLocalesForDe, :integration do
  include_context "shared cover note expectations"
end

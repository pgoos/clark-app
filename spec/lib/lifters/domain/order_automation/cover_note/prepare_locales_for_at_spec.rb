# frozen_string_literal: true

require "rails_helper"
require "lib/lifters/domain/order_automation/cover_note/shared_cover_note_expectations"

RSpec.describe Domain::OrderAutomation::CoverNote::PrepareLocalesForAt, :integration do
  include_context "shared cover note expectations"

  before do
    allow(I18n).to receive(:t).and_call_original
    allow(I18n)
      .to receive(:t)
      .with("pdf_generator.cover_note.obligation_notification")
      .and_return({ heading: "heading", text: "text" })
    allow(I18n)
      .to receive(:t)
      .with("pdf_generator.cover_note.place_of_jurisdiction")
      .and_return({ heading: "heading", text: "text" })
    allow(I18n)
      .to receive(:t)
      .with("pdf_generator.cover_note.arbitration_boards")
      .and_return({ heading: "heading", text: "text" })
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::FollowUps::CreateCalendarEvent do
  subject(:create) { described_class.new calendar_link: "LINK" }

  let(:mandate)  { object_double Mandate.new, full_name: "MANDATE", phone: "PHONE" }
  let(:due_date) { Time.current }

  let(:follow_up) do
    object_double FollowUp.new, due_date: due_date, comment: "COMMENT", mandate: mandate
  end

  it "creates a calendar event" do
    event = create.(follow_up)
    expect(event).to include "MANDATE"
    expect(event).to include "PHONE"
    expect(event).to include "LINK"
    expect(event).to include "COMMENT"
    expect(event).to include "TRIGGER:-PT15M"
    expect(event).to include due_date.strftime("%Y%m%d")
  end
end

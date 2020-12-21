# frozen_string_literal: true

require "rails_helper"

RSpec.describe Salesforce::Interactors::PerformSendEvent, :integration do
  subject { described_class.new }

  it "performs job for send event" do
    expect {
      subject.call(event_id: 1, type: "Mandate", action: "accept")
    }.to have_enqueued_job.on_queue("salesforce")
  end
end
